#pragma once

#include <DHT.h>
#include <Thermistor.h>
#include <NTC_Thermistor.h>

#define DHTPIN D5
#define DHTTYPE DHT11

#define Referenzwiderstand   10000
#define Nominalwiderstand      10000
#define Nominaltemperatur    25
#define BWert                3950

const int buttonPin = D1;
const int pumpPin = D6;

DHT dht(DHTPIN, DHTTYPE);

NTC_Thermistor* thermistor;

int sendTimer = 1;

bool wasError = false;
bool currentPump = false;

float humi = 0;
float temp_air = 0;
float temp_pool = 0;

void sensors_init() {
  pinMode(pumpPin, OUTPUT);
  digitalWrite(pumpPin, LOW);

  thermistor = new NTC_Thermistor(A0, Referenzwiderstand, Nominalwiderstand, Nominaltemperatur, BWert);
}

void sensors_update() {
  humi = dht.readHumidity();
  temp_air = dht.readTemperature();
  temp_pool = thermistor->readCelsius();
}

bool pump_toogle() {
#ifdef DEBUG
  Serial.print("TogglePump: ");
#endif
  currentPump = !currentPump;
  Serial.println(currentPump);
  digitalWrite(pumpPin, currentPump);

  return currentPump;
}