#pragma once
#include "wifi.h"
#include "sensors.h"
#include <Wire.h>
bool dp_timer();
int wifi_retryCounter;

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

enum DisplayState {
  START,
  WIFI_CONNECTING,
  WIFI_CONNECTED,
  HOST_FAILURE,
  ON,
  OFF
};

enum DisplayState display_state = START;

int getLcdAddress() {
  Wire.begin(2,0);
  byte error, address;
#ifdef DEBUG
  Serial.println("Scanning...");
#endif
  for(address = 1; address < 127; address++ ) {
    Wire.beginTransmission(address);
    error = Wire.endTransmission();
    if (error == 0) {
#ifdef DEBUG
      Serial.print("I2C device found at address 0x");
      if (address<16) {
        Serial.print("0");
      }
      Serial.println(address,HEX);
#endif
      return address;
    } 
  }
#ifdef DEBUG
  Serial.println("No I2C devices found\n");
#endif
  return 0;
}

LiquidCrystal_I2C lcd(getLcdAddress(), 16, 2);


int dp_clearNum = -1;

int dp_displayTimer = 11;

void clearLcd(int num) {
  if(num != dp_clearNum) {
    dp_clearNum = num;
    lcd.clear();
  }
}

void dp_init() {
  lcd.init();
  lcd.backlight();
  lcd.print("Startet...");
  lcd.createChar(0, grad);
}

void dp_wifiConnecting() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Verbinde mit");
  lcd.setCursor(0, 1);
  lcd.print("WLAN...");
}

void dp_wifiConnected() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("WLAN Verbunden!");
  lcd.setCursor(0, 1);
  lcd.print("Verbinde...");
}

void dp_hostFailure() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Verb. Fehler!"); 
  lcd.setCursor(0, 1);
  lcd.print("Neuversuch in " + String(wifi_retryCounter)); 
}

void dp_on() {
  if (isnan(humi) || isnan(temp_pool) || isnan(temp_air)) {
    clearLcd(1);
    lcd.setCursor(0, 0);
    lcd.print("Fehler: Sensor");
    lcd.setCursor(0, 1);
    if(isnan(humi)) {
      lcd.print("Humi ");
    }
    if(isnan(temp_air)) {
      lcd.print("Aussen ");
    }
    if(isnan(temp_pool)) {
      lcd.print("Wasser ");
    }
  } else {
      clearLcd(0);
      lcd.setCursor(0, 0);
      lcd.print("Wasser: " + String(temp_pool) + "C");
      lcd.write(0);
      lcd.setCursor(0, 1);
      lcd.print("Aussen: " + String(temp_air) + "C");
      lcd.write(0);
  }
}

void dp_update() {
  if (dp_timer()) return;

  switch (display_state) {
    case WIFI_CONNECTING:
      dp_wifiConnecting();
      break;
    case WIFI_CONNECTED:
      dp_wifiConnected();
      break;
    case HOST_FAILURE:
      dp_hostFailure();
      break;
    case ON:
      dp_on();
      break;
  }
}

void dp_updateState(enum DisplayState newState) {
  if (display_state == newState) return;

  switch (newState) {
    case OFF:
      lcd.noBacklight();
      break;
    case ON:
      lcd.backlight();
      break;
  }

  display_state = newState;
  dp_update();
}

bool dp_timer() {
  if (display_state != ON) return false;

  if (dp_displayTimer == 0) {
    return true;
  }
  
  if (--dp_displayTimer == 0) {
    dp_updateState(OFF);
    return true;
  }

  return false;
}

void dp_enable() {
  dp_displayTimer = 11;

  if (display_state == OFF) {
    dp_updateState(ON);
  }
}