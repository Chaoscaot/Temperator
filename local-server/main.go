package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"gopkg.in/yaml.v3"
	"net"
	"net/http"
	"os"
	"strconv"
	"strings"
)

type DataPoint struct {
	Humidity float64
	Temp1    float64
	Temp2    float64
}

func handleConnection(conn net.Conn, client *http.Client, config *Config) {
	defer func(conn net.Conn) {
		err := conn.Close()
		if err != nil {
			fmt.Println(err)
			return
		}
	}(conn)

	var index = 0
	var points = make([]DataPoint, config.Batch)
	status := ""

	for {
		data, err := bufio.NewReader(conn).ReadString('\n')
		if err != nil {
			fmt.Println(err)
			err := conn.Close()
			if err != nil {
				fmt.Println(err)
				return
			}
			return
		}

		data = strings.TrimSpace(data)

		if strings.HasPrefix(data, "error: ") {
			fmt.Println(data)
			if status != data {
				fmt.Println("Status", data)
				status = data
				sendStatus(client, status, config)
			}
			continue
		}
		if status != "ok" {
			fmt.Println("Status ok")
			status = "ok"
			sendStatus(client, status, config)
		}

		dArr := strings.Split(data, ";")

		if len(dArr) != 3 {
			fmt.Println("Invalid data", data)
			continue
		}

		dMap := map[string]float64{}

		for _, v := range dArr {
			kv := strings.Split(v, ":")
			float, err := strconv.ParseFloat(kv[1], 64)
			if err != nil {
				fmt.Println(err, data)
				continue
			}
			dMap[kv[0]] = float
		}

		points[index] = DataPoint{
			Humidity: dMap["Hum"],
			Temp1:    dMap["Temp1"],
			Temp2:    dMap["Temp2"],
		}

		index++

		fmt.Println("Data point nr.", index, "received")

		if index == config.Batch {
			index = 0
			upload := map[string]any{}

			sumHum := 0.0
			sumTemp1 := 0.0
			sumTemp2 := 0.0

			for _, v := range points {
				sumHum += v.Humidity
				sumTemp1 += v.Temp1
				sumTemp2 += v.Temp2
			}

			upload["device_id"] = config.DeviceID
			upload["Hum"] = sumHum / float64(config.Batch)
			upload["Temp1"] = sumTemp1 / float64(config.Batch)
			upload["Temp2"] = sumTemp2 / float64(config.Batch)

			dJson, err := json.Marshal(upload)

			req, err := http.NewRequest("POST", config.UploadUrl+"/api/v1/data", bytes.NewReader(dJson))
			if err != nil {
				fmt.Println(err, data)
				continue
			}

			req.Header.Set("Content-Type", "application/json")
			req.Header.Set("X-Token", config.Token)

			_, err = client.Do(req)
			if err != nil {
				fmt.Println(err, data)
				continue
			}

		}
	}
}

func sendStatus(client *http.Client, status string, config *Config) {
	upload := map[string]string{}

	upload["device_id"] = config.DeviceID
	upload["status"] = status

	dJson, err := json.Marshal(upload)

	req, err := http.NewRequest("POST", config.UploadUrl+"/api/v1/status", bytes.NewReader(dJson))
	if err != nil {
		fmt.Println(err)
		return
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Token", config.Token)

	_, err = client.Do(req)
	if err != nil {
		fmt.Println(err)
		return
	}
}

type Config struct {
	Token     string `yaml:"token"`
	DeviceID  string `yaml:"device_id"`
	Port      string `yaml:"port"`
	UploadUrl string `yaml:"upload_url"`
	Batch     int    `yaml:"batch"`
}

func main() {
	conf, err := os.Open("config.yml")
	if err != nil {
		fmt.Println(err)
		return
	}
	var config Config
	err = yaml.NewDecoder(conf).Decode(&config)
	if err != nil {
		fmt.Println(err)
		return
	}

	server, err := net.Listen("tcp", ":"+config.Port)
	if err != nil {
		fmt.Println(err)
		return
	}

	defer func(server net.Listener) {
		err := server.Close()
		if err != nil {
			fmt.Println(err)
			return
		}
	}(server)

	client := http.Client{}

	for {
		conn, err := server.Accept()
		if err != nil {
			fmt.Println(err)
			continue
		}

		go handleConnection(conn, &client, &config)
	}
}
