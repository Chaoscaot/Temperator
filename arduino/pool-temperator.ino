#include "DHT.h"
#include <ESP8266WiFi.h>
#include <ESP8266WiFiMulti.h>
#include <Thermistor.h>
#include <NTC_Thermistor.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

#define DHTPIN 14
#define DHTTYPE DHT11

#ifndef STASSID
#define STASSID "Max-WLAN"
#define STAPSK "Max-WLAN"
#endif

#define Referenzwiderstand   10000 // Widerstandswert des Widerstandes der mit dem NTC in Reihe geschaltet wurde.
#define Nominalwiderstand      10000 // Widerstand des NTC bei Normaltemperatur
#define Nominaltemperatur    25 // Temperatur, bei der der NTC den angegebenen Widerstand hat
#define BWert                3950 // Beta Koeffizient(zu finden im Datenblatt des NTC)

const char* ssid = STASSID;
const char* password = STAPSK;

const char* host = "192.168.178.36";
const uint16_t port = 8090;

DHT dht(DHTPIN, DHTTYPE);

ESP8266WiFiMulti WiFiMulti;

WiFiClient client;

Thermistor* thermistor;

LiquidCrystal_I2C lcd(0x3F, 16, 2);

int sendTimer = 1;

int clearNum = -1;

byte grad[8] = {
	0b01100,
	0b10010,
	0b10010,
	0b01100,
	0b00000,
	0b00000,
	0b00000,
	0b00000
};

void setup() {
  Serial.begin(115200);
  dht.begin();
  Wire.begin(2,0);
  lcd.init();
  lcd.backlight();
  lcd.print("Startet...");
  thermistor = new NTC_Thermistor(A0, Referenzwiderstand, Nominalwiderstand, Nominaltemperatur, BWert);

  // We start by connecting to a WiFi network
  WiFi.mode(WIFI_STA);
  WiFiMulti.addAP(ssid, password);

  Serial.println();
  Serial.println();
  lcd.setCursor(0, 1);
  lcd.print("Verbinde zu WiFi"); 
  Serial.print("Wait for WiFi... ");

  while (WiFiMulti.run() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }

  Serial.println("");
  lcd.clear();
  lcd.setCursor(0, 1);
  lcd.print("WiFi Verbunden"); 
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
  lcd.createChar(0, grad);
}

void clearLcd(int num) {
  if(num != clearNum) {
    clearNum = num;
    lcd.clear();
  }
}

void loop() {
  if(!client.connected()) {
    if (!client.connect(host, port)) {
      Serial.println("connection failed");
      Serial.println("wait 5 sec...");
      clearLcd(3);
      lcd.setCursor(0, 0);
      lcd.print("Verb. Fehler!"); 
      for(int i = 5; i > 0; i--) {
      lcd.setCursor(0, 1);
        lcd.print("Neuversuch: " + String(i)); 
        delay(1000);
      }
      return;
    } else {
      sendTimer = 1;
    }
  }

  // read humidity
  float humi  = dht.readHumidity();
  // read temperature as Celsius
  float tempC = dht.readTemperature();

  float temp = thermistor->readCelsius();

  // check if any reads failed
  if (isnan(humi) || isnan(tempC) || isnan(temp)) {
    client.println("error: Failed to read from sensor!");

    clearLcd(1);
    lcd.setCursor(0, 0);
    lcd.print("Fehler: Sensor");
    lcd.setCursor(0, 1);
    if(isnan(humi)) {
      lcd.print("Humi ");
    }
    if(isnan(tempC)) {
      lcd.print("Aussen ");
    }
    if(isnan(temp)) {
      lcd.print("Wasser ");
    }
  } else {

    clearLcd(0);
    lcd.setCursor(0, 0);
    lcd.print("Wasser: " + String(temp) + "C");
    lcd.write(0);
    lcd.setCursor(0, 1);
    lcd.print("Aussen: " + String(tempC) + "C");
    lcd.write(0);
    
    if(--sendTimer == 0) {
      client.print("Hum:");
      client.print(humi);

      client.print(";"); 

      client.print("Temp1:");
      client.print(tempC);

      client.print(";"); 

      client.print("Temp2:");
      client.println(temp);
      sendTimer = 60;
    }
  }
  delay(1000);
}
