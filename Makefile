default: build

build: build-all copy zip

copy: _dir copy-local copy-public copy-frontend copy-service copy-defaults

_dir:
	mkdir -p out

copy-local:
	cp local-server/out/local-server out/local-server

copy-public:
	mv public-server/out/public-server out/public-server

copy-frontend:
	mv frontend/build/app/outputs/apk/release/app-release.apk out/app-release.apk

copy-defaults:
	mkdir -p out/configs/
	cp local-server/config.default.yml out/configs/local-server.yml
	cp public-server/config.default.yml out/configs/public-server.yml

copy-service:
	mkdir -p out/services/
	cp local-server/server.service out/services/local-server.service
	cp public-server/server.service out/services/public-server.service

clean:
	rm -rf out

zip:
	cd out && zip -r release.zip .

build-all: build-local build-public build-frontend

build-local:
	cd local-server && env GOOS=linux GOARCH=arm GOARM=5 go build -o out/local-server

build-public:
	cd public-server && go build -o out/public-server

build-frontend:
	cd frontend && flutter build apk --release