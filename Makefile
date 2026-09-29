SHELL := /usr/bin/env bash

.DEFAULT_GOAL := android

.PHONY: \
	android \
	check \
	build \
	install \
	up \
	backend \
	doctor \
	help

android:
	@bash ./dev.sh android

check:
	@bash ./dev.sh check

build:
	@bash ./dev.sh build

install:
	@bash ./dev.sh install

up:
	@bash ./dev.sh up

backend:
	@bash ./dev.sh backend

doctor:
	@bash ./dev.sh doctor

help:
	@bash ./dev.sh help