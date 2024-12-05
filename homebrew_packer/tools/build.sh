#! /usr/bin/env bash

if [[ $1 == "build" ]]; then
	set -ex
	go mod tidy
	GOOS=darwin GOARCH=arm64 go build -o cover_path .
	set +ex
elif [[ $1 == "clean" ]]; then
	set -xe
	rm -rf ./cover_path
	set +xe
fi
