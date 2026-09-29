SHELL := /usr/bin/env bash

.DEFAULT_GOAL := android

IDE_FLUTTER := $(HOME)/.local/share/flutter-sdk/flutter-3.47.3/bin/flutter

.PHONY: \
	android \
	check \
	build \
	install \
	up \
	backend \
	doctor \
	ide \
	help

android:
	@bash ./dev.sh android
	@$(MAKE) ide

check:
	@bash ./dev.sh check
	@$(MAKE) ide

build:
	@bash ./dev.sh build
	@$(MAKE) ide

install:
	@bash ./dev.sh install

up:
	@bash ./dev.sh up

backend:
	@bash ./dev.sh backend

doctor:
	@bash ./dev.sh doctor

ide:
	@if [ -x "$(IDE_FLUTTER)" ]; then \
		echo ""; \
		echo "==> Sinkronisasi Flutter untuk Android Studio"; \
		cd mobile && "$(IDE_FLUTTER)" pub get; \
		echo "✓ Android Studio dependencies siap"; \
	else \
		echo "! Flutter SDK host belum tersedia di:"; \
		echo "  $(IDE_FLUTTER)"; \
	fi

help:
	@bash ./dev.sh help