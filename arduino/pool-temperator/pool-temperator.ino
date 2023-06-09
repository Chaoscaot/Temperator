#include <DHT.h>
#include <ESP8266WiFi.h>
#include <ESP8266WiFiMulti.h>
#include <Thermistor.h>
#include <NTC_Thermistor.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include "secret.h"

#define DHTPIN 14
#define DHTTYPE DHT11

#ifndef STASSID
#define STASSID WLAN_NAME
#define STAPSK WLAN_PASSWORD
#endif

#define Referenzwiderstand   10000
#define Nominalwiderstand      10000
#define Nominaltemperatur    25
#define BWert                3950

const char* ssid = STASSID;
const char* password = STAPSK;

const char* host = "192.168.178.36";
const uint16_t port = 8090;

const int buttonPin = D1;

DHT dht(DHTPIN, DHTTYPE);

ESP8266WiFiMulti WiFiMulti;

WiFiClient client;

Thermistor* thermistor;

int sendTimer = 1;

int clearNum = -1;

int displayTimer = 0;

bool wasError = false;

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

int getLcdAddress() {
  Serial.begin(115200);
  Wire.begin(2,0);
  byte error, address;
  Serial.println("Scanning...");
  for(address = 1; address < 127; address++ ) {
    Wire.beginTransmission(address);
    error = Wire.endTransmission();
    if (error == 0) {
      Serial.print("I2C device found at address 0x");
      if (address<16) {
        Serial.print("0");
      }
      Serial.println(address,HEX);
      return address;
    } 
  }
  Serial.println("No I2C devices found\n");
  return 0;
}

LiquidCrystal_I2C lcd(getLcdAddress(), 16, 2);

void setup() {
  pinMode(buttonPin, INPUT);
  dht.begin();
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
  displayTimer = 11;
}

void clearLcd(int num) {
  if(num != clearNum) {
    clearNum = num;
    lcd.clear();
  }
}

int retryCounter = 0;

void setTimer(int time) {
    if(displayTimer == 0) {
      lcd.display();
      lcd.backlight();
    }
    displayTimer = time;
}

void kmsLoop() {
  if(displayTimer != 0) {
    displayTimer--;
    if(displayTimer == 0) {
      lcd.clear();
      lcd.noDisplay();
      lcd.noBacklight();
    }
  }

  if(!client.connected()) {
    if(retryCounter == 0) {
      if (!client.connect(host, port)) {
        Serial.println("connection failed");
        Serial.println("wait 5 sec...");
        retryCounter = 5;
      } else {
        sendTimer = 1;
        retryCounter = 0;
      }
    }

    if(retryCounter != 0) {
      if(displayTimer != 0) {
        clearLcd(3);
        lcd.setCursor(0, 0);
        lcd.print("Verb. Fehler!"); 
        lcd.setCursor(0, 1);
        lcd.print("Neuversuch: " + String(retryCounter)); 
      }
      retryCounter--;
      return;
    }
  }

  // read humidity
  float humi  = dht.readHumidity();
  // read temperature as Celsius
  float tempC = dht.readTemperature();

  float temp = thermistor->readCelsius();

  // check if any reads failed
  if (isnan(humi) || isnan(tempC) || isnan(temp)) {
    wasError = true;
    client.println("error: Failed to read from sensor!");

    if(displayTimer != 0) {
      clearLcd(1);
      lcd.setCursor(0, 0);
      lcd.print("Fehler: Sensor");
      lcd.setCursor(0, 1);
    }
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
    if(displayTimer != 0) {
      clearLcd(0);
      lcd.setCursor(0, 0);
      lcd.print("Wasser: " + String(temp) + "C");
      lcd.write(0);
      lcd.setCursor(0, 1);
      lcd.print("Aussen: " + String(tempC) + "C");
      lcd.write(0);
    }
    
    if(wasError) {
      wasError = false;
      sendTimer = 1;
    }

    if(--sendTimer == 0) {
      client.print("Hum:");
      client.print(humi);

      client.print(";"); 

      client.print("Temp1:");
      client.print(tempC);

      client.print(";"); 

      client.print("Temp2:");
      client.println(temp);
      sendTimer = 60 - 4;
    }
  }
}

int kmsTimer = 20;

void loop() {
  if(digitalRead(buttonPin) == HIGH) {
    setTimer(11);
  }
  if(kmsTimer++ == 1000 / 50) {
    kmsLoop();
    kmsTimer = 0;
  }
  delay(50);
}
