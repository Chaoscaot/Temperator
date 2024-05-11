#pragma once
#include <ESP8266WiFi.h>
#include "config.h"
#include "display.h"

const char* ssid = WLAN_NAME;
const char* password = WLAN_PASSWORD;

const char* host = WLAN_HOST;
const uint16_t port = 8090;

ESP8266WiFiMulti WiFiMulti;

WiFiClient client;

void wifi_hostConnect() {
  while (!client.connected()) {
    if(!client.connect(WLAN_HOST, WLAN_PORT)) {
      wifi_retryCounter = 5;
      dp_updateState(HOST_FAILURE);
      while (--wifi_retryCounter != 0) {
        delay(1000);
        dp_update();
      }
      delay(1000);
      dp_updateState(WIFI_CONNECTED);
    }
  }
  client.println("Connected!");
#ifdef DEBUG
  Serial.println(client.remoteIP());
#endif
  dp_updateState(ON);
}

bool wifi_checkConnected() {
  client.flush();
  if (client.connected()) return true;

  dp_enable();
  wifi_hostConnect();
  return false;
}

void wifi_connect() {
  WiFi.mode(WIFI_STA);
  WiFiMulti.addAP(ssid, password);

#ifdef DEBUG
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  Serial.print("Wait for WiFi... ");
#endif

  dp_updateState(WIFI_CONNECTING);

  while (WiFiMulti.run() != WL_CONNECTED) {
#ifdef DEBUG
    Serial.print(".");
#endif
    delay(500);
  }

  dp_updateState(WIFI_CONNECTED);
#ifdef DEBUG
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
#endif
  wifi_hostConnect();
}
