int getInt() {
  Serial.begin(115200);
  return 1;
}

int _ = getInt();

#include "config.h"

#include <ESP8266WiFi.h>
#include <ESP8266WiFiMulti.h>
#include <LiquidCrystal_I2C.h>
#include "wifi.h"
#include "display.h"
#include "sensors.h"
#include "io.h"

int debounce = 0;

void IRAM_ATTR interrupt() {
  if(debounce == 0) {
    if(dp_displayTimer == 0) {
      dp_enable();
    }

    debounce++;
  }
}

void setup() {
  pinMode(buttonPin, INPUT);
  attachInterrupt(digitalPinToInterrupt(buttonPin), interrupt, RISING);

  sensors_init();
  dp_init();
  wifi_connect();
}

int counter = 0;

void loop() {
  io_check();

  if (counter == 0) {
    debounce = 0;
    sensors_update();
    io_asend();
    dp_update();
  }

  delay(50);
  if(counter++ == 20) counter = 0;
}

/*

int retryCounter = 0;

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

    while(client.available()) {
      char buf[5];
      buf[4] = 0;
      client.read(buf, 4);
      Serial.write(buf);
      Serial.write(strcmp(buf, "send"));
      if(!strcmp(buf, "send")) {
        humi  = dht.readHumidity();
        tempC = dht.readTemperature();
        temp = thermistor->readCelsius();
        client.print("Hum:");
        client.print(humi);
        client.print(";"); 
        client.print("Temp1:");
        client.print(tempC);
        client.print(";");
        client.print("Temp2:");
        client.print(temp);
        client.print(";");
        client.print("Pump:");
        client.println(currentPump);
      } else if(!strcmp(buf, "pump")) {
        currentPump = !currentPump;
        digitalWrite(pumpPin, currentPump);
      }
    }

    if(--sendTimer == 0) {
      client.print("Hum:");
      client.print(humi);

      client.print(";"); 

      client.print("Temp1:");
      client.print(tempC);

      client.print(";"); 

      client.print("Temp2:");
      client.print(temp);

      client.print(";"); 

      client.print("Pump:");
      client.println(currentPump);
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
*/