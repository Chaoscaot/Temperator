#pragma once

#include <string.h>
#include "wifi.h"
#include "display.h"

#define BUF_LEN 16

bool io_autosend = false;

void io_send() {
  client.print("Hum:");
  client.print(humi);
  client.print(";"); 
  client.print("TempPool:");
  client.print(temp_pool);
  client.print(";");
  client.print("TempAir:");
  client.print(temp_air);
  client.print(";");
  client.print("Pump:");
  client.println(String(currentPump));
}

void io_asend() {
  if (io_autosend) {
    wifi_checkConnected();
    io_send();
  }
}

void io_check() {
  wifi_checkConnected();

  if(client.available()) {
      char buf[BUF_LEN];
      int len = client.read(buf, BUF_LEN - 1);
      buf[len] = 0;
      if (buf[len - 1] == '\n') {
        buf[len - 1] = 0;
      }
      if(!strcmp("send", buf)) {
        io_send();
      } else if(!strcmp("display", buf)) {
        dp_enable();
      } else if(!strcmp("pump", buf)) {
        client.println(String(pump_toogle()));
      } else if(!strcmp("auto", buf)) {
        io_autosend = !io_autosend;
      }
  }
}