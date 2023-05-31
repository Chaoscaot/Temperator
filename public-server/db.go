package main

import (
	_ "embed"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"time"
)

type DataPoint struct {
	Time        time.Time `gorm:"autoCreateTime;primaryKey"`
	DeviceID    string    `gorm:"primaryKey;foreignKey:DevId"`
	Humidity    float64
	OutsideTemp float64
	WaterTemp   float64
}

type Status struct {
	Time     time.Time `gorm:"autoCreateTime;primaryKey"`
	DeviceID string    `gorm:"primaryKey;foreignKey:DevId"`
	Status   string
}

type Device struct {
	DevId string `gorm:"primaryKey"`
	Name  string
}

func OpenConnection(config *Config) (*gorm.DB, error) {
	dsn := config.User + ":" + config.Password + "@tcp(" + config.Host + ":" + config.Port + ")/" + config.Database + "?charset=utf8mb4&parseTime=True&loc=Local"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		return nil, err
	}

	err = db.AutoMigrate(&DataPoint{}, &Status{}, &Device{})

	if err != nil {
		return nil, err
	}

	return db, nil
}
