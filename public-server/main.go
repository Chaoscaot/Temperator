package main

import (
	"errors"
	"fmt"
	"github.com/gin-gonic/gin"
	"gopkg.in/yaml.v3"
	"gorm.io/gorm"
	"math/rand"
	"os"
	"time"
)

type AddData struct {
	DeviceID    string  `json:"device_id"`
	Humidity    float64 `json:"Hum"`
	OutsideTemp float64 `json:"Temp1"`
	WaterTemp   float64 `json:"Temp2"`
}

type ChangeStatus struct {
	DeviceID string `json:"device_id"`
	Status   string `json:"status"`
}

type Config struct {
	Database   string `yaml:"database"`
	User       string `yaml:"user"`
	Password   string `yaml:"password"`
	Host       string `yaml:"host"`
	Port       string `yaml:"port"`
	Token      string `yaml:"token"`
	ServerPort string `yaml:"serverPort"`
}

func TokenValidator(config *Config) gin.HandlerFunc {
	return func(context *gin.Context) {
		tok := context.GetHeader("X-Token")
		if tok == "" || tok != config.Token {
			time.Sleep(time.Duration(rand.Float32() * 100))
			context.AbortWithStatusJSON(401, gin.H{"error": "invalid token or no token provided"})
			return
		}
	}
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
	db, err := OpenConnection(&config)

	if err != nil {
		fmt.Println(err)
		return
	}

	r := gin.Default()
	r.Use(TokenValidator(&config))

	r.POST("/api/v1/data", func(c *gin.Context) {
		var data AddData
		err := c.Bind(&data)
		if err != nil {
			c.JSON(400, gin.H{"error": "invalid data"})
			return
		}

		dataPoint := DataPoint{
			Time:        time.Now(),
			DeviceID:    data.DeviceID,
			Humidity:    data.Humidity,
			OutsideTemp: data.OutsideTemp,
			WaterTemp:   data.WaterTemp,
		}

		err = db.Create(&dataPoint).Error

		if err != nil {
			c.JSON(500, gin.H{"error": "internal server error"})
			return
		}

		c.JSON(200, gin.H{"success": true})
	})

	r.POST("/api/v1/status", func(c *gin.Context) {
		var data ChangeStatus
		err := c.Bind(&data)
		if err != nil {
			c.JSON(400, gin.H{"error": "invalid data"})
			return
		}

		status := Status{}

		err = db.Where("device_id = ?", data.DeviceID).Order("time desc").First(&status).Error
		if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(500, gin.H{"error": "internal server error"})
			return
		}

		if errors.Is(err, gorm.ErrRecordNotFound) || status.Status != data.Status {

			status = Status{
				Time:     time.Now(),
				DeviceID: data.DeviceID,
				Status:   data.Status,
			}

			status.Status = data.Status
			err = db.Create(&status).Error
			if err != nil {
				c.JSON(500, gin.H{"error": "internal server error"})
				return
			}
			c.JSON(200, gin.H{"success": true})
		} else {
			c.JSON(200, gin.H{"success": false})
		}
	})

	r.GET("/api/v1/devices", func(c *gin.Context) {
		var devices []Device
		err := db.Find(&devices).Error
		if err != nil {
			c.JSON(500, gin.H{"error": "internal server error"})
			return
		}
		c.JSON(200, devices)
	})

	r.GET("/api/v1/devices/:id/status", func(context *gin.Context) {
		var status Status
		err := db.Where("device_id = ?", context.Param("id")).Order("time desc").First(&status).Error
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				context.JSON(404, gin.H{"error": "device not found"})
				return
			}
			context.JSON(500, gin.H{"error": "internal server error"})
			return
		}

		var result struct {
			Time     int64
			DeviceID string
			Status   string
		}

		result.Time = status.Time.UnixMilli()
		result.DeviceID = status.DeviceID
		result.Status = status.Status

		context.JSON(200, result)
	})

	r.GET("/api/v1/devices/:id/current", func(context *gin.Context) {
		var data DataPoint
		err := db.Where("device_id = ?", context.Param("id")).Order("time desc").First(&data).Error
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				context.JSON(404, gin.H{"error": "device not found"})
				return
			}
			context.JSON(500, gin.H{"error": "internal server error"})
			return
		}

		var result struct {
			Time        int64
			DeviceID    string
			Humidity    float64
			OutsideTemp float64
			WaterTemp   float64
		}

		result.Time = data.Time.UnixMilli()
		result.DeviceID = data.DeviceID
		result.Humidity = data.Humidity
		result.OutsideTemp = data.OutsideTemp
		result.WaterTemp = data.WaterTemp

		context.JSON(200, result)
	})

	r.GET("/api/v1/devices/:id/chart", func(context *gin.Context) {
		var result []struct {
			Hourcol                          time.Time
			Humidity, OutsideTemp, WaterTemp float64
		}
		err := db.Raw("SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(time) - MOD(UNIX_TIMESTAMP(time), 3600)) as hourcol, AVG(humidity) as Humidity, AVG(outside_temp) as OutsideTemp, AVG(water_temp) as WaterTemp FROM data_points WHERE TIMESTAMPDIFF(hour, time, NOW()) < 24 GROUP BY hourcol").Scan(&result).Error
		if err != nil {
			context.JSON(500, gin.H{"error": "internal server error"})
			return
		}

		var data []struct {
			Hourcol                          int64
			Humidity, OutsideTemp, WaterTemp float64
		}

		for _, v := range result {
			data = append(data, struct {
				Hourcol                          int64
				Humidity, OutsideTemp, WaterTemp float64
			}{
				v.Hourcol.UnixMilli(),
				v.Humidity,
				v.OutsideTemp,
				v.WaterTemp,
			})
		}

		context.JSON(200, data)
	})

	r.Run(":" + config.ServerPort)
}
