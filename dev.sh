#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(
  cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
  pwd
)"

cd "$ROOT_DIR"

APP_ID="${APP_ID:-com.ki1bot.absensi_flutter}"
MAIN_ACTIVITY="${MAIN_ACTIVITY:-.MainActivity}"

API_PORT="${API_PORT:-8080}"
API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:${API_PORT}}"
HEALTH_URL="${HEALTH_URL:-http://127.0.0.1:${API_PORT}/health}"

APK_PATH="${APK_PATH:-$ROOT_DIR/mobile/build/app/outputs/flutter-apk/app-debug.apk}"

AVD_NAME="${AVD_NAME:-Pixel_9_Pro}"
CAMERA_BACK="${CAMERA_BACK:-webcam0}"

AUTO_START_EMULATOR="${AUTO_START_EMULATOR:-1}"

DEVICE_SERIAL=""

step() {
  printf '\n\033[1;34m==>\033[0m %s\n' "$1"
}

success() {
  printf '\033[1;32m✓\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33m!\033[0m %s\n' "$1"
}

fail() {
  printf '\033[1;31m✗\033[0m %s\n' "$1" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

compose() {
  docker compose "$@"
}

resolve_adb() {
  local candidates=()

  if [[ -n "${ANDROID_HOME:-}" ]]; then
    candidates+=(
      "$ANDROID_HOME/platform-tools/adb"
    )
  fi

  if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
    candidates+=(
      "$ANDROID_SDK_ROOT/platform-tools/adb"
    )
  fi

  candidates+=(
    "$HOME/Android/Sdk/platform-tools/adb"
  )

  local candidate

  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  if command_exists adb; then
    command -v adb
    return 0
  fi

  return 1
}

resolve_emulator() {
  local candidates=()

  if [[ -n "${ANDROID_HOME:-}" ]]; then
    candidates+=(
      "$ANDROID_HOME/emulator/emulator"
    )
  fi

  if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
    candidates+=(
      "$ANDROID_SDK_ROOT/emulator/emulator"
    )
  fi

  candidates+=(
    "$HOME/Android/Sdk/emulator/emulator"
  )

  local candidate

  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  if command_exists emulator; then
    command -v emulator
    return 0
  fi

  return 1
}

ADB_BIN="${ADB_BIN:-$(resolve_adb || true)}"
EMULATOR_BIN="${EMULATOR_BIN:-$(resolve_emulator || true)}"

check_requirements() {
  step "Memeriksa environment"

  command_exists docker || fail "Docker tidak ditemukan."
  command_exists curl || fail "curl tidak ditemukan."

  docker compose version >/dev/null 2>&1 ||
    fail "Docker Compose tidak tersedia."

  docker info >/dev/null 2>&1 ||
    fail "Docker Engine belum berjalan."

  if [[ -z "$ADB_BIN" || ! -x "$ADB_BIN" ]]; then
    fail "ADB Android SDK tidak ditemukan."
  fi

  if [[ ! -f "$ROOT_DIR/.env" ]]; then
    fail "File .env tidak ditemukan di root project."
  fi

  success "Environment siap"

  printf 'ADB      : %s\n' "$ADB_BIN"

  if [[ -n "$EMULATOR_BIN" ]]; then
    printf 'Emulator : %s\n' "$EMULATOR_BIN"
  fi
}

git_has_changes() {
  if ! command_exists git; then
    return 1
  fi

  [[ -n "$(git status --porcelain -- "$@" 2>/dev/null)" ]]
}

wait_backend() {
  step "Menunggu backend"

  local attempt

  for attempt in $(seq 1 60); do
    if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
      success "Backend aktif di $HEALTH_URL"
      return 0
    fi

    sleep 2
  done

  warn "Backend belum sehat. Log terakhir:"

  compose logs --tail=80 backend || true

  fail "Backend gagal menjadi healthy."
}

start_services() {
  step "Menyalakan PostgreSQL"

  compose up -d db

  if git_has_changes backend compose.yaml; then
    step "Perubahan backend terdeteksi"

    compose build backend

    compose up -d \
      --force-recreate \
      backend
  else
    step "Menyalakan backend"

    compose up -d backend
  fi

  if git_has_changes mobile/Dockerfile compose.yaml; then
    step "Perubahan Flutter Docker terdeteksi"

    compose build flutter

    compose up -d \
      --force-recreate \
      flutter
  else
    step "Menyalakan container Flutter"

    compose up -d flutter
  fi

  wait_backend
}

flutter_pub_get() {
  step "Flutter pub get"

  compose exec -T flutter \
    flutter pub get

  success "Dependency Flutter siap"
}

flutter_format() {
  step "Format Dart"

  compose exec -T flutter \
    dart format lib test

  success "Format selesai"
}

flutter_analyze() {
  step "Flutter analyze"

  compose exec -T flutter \
    flutter analyze

  success "Flutter analyze bersih"
}

flutter_test() {
  step "Flutter test"

  compose exec -T flutter \
    flutter test

  success "Semua test lulus"
}

validate_flutter() {
  flutter_pub_get
  flutter_format
  flutter_analyze
  flutter_test
}

remove_old_apk() {
  step "Menghapus APK build sebelumnya"

  rm -f "$APK_PATH"

  success "APK lama dihapus"
}

build_apk() {
  remove_old_apk

  step "Build APK debug"

  compose exec -T flutter \
    flutter build apk \
    --debug \
    --dart-define="API_BASE_URL=$API_BASE_URL"

  if [[ ! -f "$APK_PATH" ]]; then
    fail "APK tidak ditemukan setelah proses build."
  fi

  success "APK berhasil dibuat"

  ls -lh "$APK_PATH"
}

adb_start_server() {
  step "Menyalakan ADB server"

  "$ADB_BIN" start-server >/dev/null

  success "ADB server aktif"
}

connected_devices() {
  "$ADB_BIN" devices |
    awk '
      NR > 1 && $2 == "device" {
        print $1
      }
    '
}

wait_for_android_boot() {
  step "Menunggu Android selesai boot"

  local attempt
  local boot_completed

  for attempt in $(seq 1 90); do
    boot_completed="$(
      "$ADB_BIN" \
        -s "$DEVICE_SERIAL" \
        shell getprop sys.boot_completed \
        2>/dev/null |
        tr -d '\r'
    )"

    if [[ "$boot_completed" == "1" ]]; then
      success "Android siap"
      return 0
    fi

    sleep 2
  done

  fail "Android tidak selesai boot dalam waktu yang ditentukan."
}

start_emulator() {
  if [[ "$AUTO_START_EMULATOR" != "1" ]]; then
    fail "Tidak ada device. AUTO_START_EMULATOR dinonaktifkan."
  fi

  if [[ -z "$EMULATOR_BIN" || ! -x "$EMULATOR_BIN" ]]; then
    fail "Android Emulator tidak ditemukan."
  fi

  if ! "$EMULATOR_BIN" -list-avds |
    grep -Fxq "$AVD_NAME"; then
    warn "AVD '$AVD_NAME' tidak ditemukan."

    printf '\nAVD yang tersedia:\n'

    "$EMULATOR_BIN" -list-avds

    exit 1
  fi

  step "Menyalakan emulator $AVD_NAME"

  nohup \
    "$EMULATOR_BIN" \
    "@$AVD_NAME" \
    -camera-back "$CAMERA_BACK" \
    >/tmp/absensi-flutter-emulator.log \
    2>&1 &

  local attempt
  local found=""

  for attempt in $(seq 1 60); do
    found="$(
      connected_devices |
        grep '^emulator-' |
        head -n 1 ||
        true
    )"

    if [[ -n "$found" ]]; then
      DEVICE_SERIAL="$found"

      success "Emulator terdeteksi: $DEVICE_SERIAL"

      wait_for_android_boot

      return 0
    fi

    sleep 2
  done

  warn "Log emulator:"

  tail -n 80 \
    /tmp/absensi-flutter-emulator.log \
    2>/dev/null ||
    true

  fail "Emulator gagal terdeteksi ADB."
}

select_device() {
  adb_start_server

  if [[ -n "${ADB_SERIAL:-}" ]]; then
    if "$ADB_BIN" devices |
      awk 'NR > 1 && $2 == "device" {print $1}' |
      grep -Fxq "$ADB_SERIAL"; then
      DEVICE_SERIAL="$ADB_SERIAL"

      success "Device dipilih: $DEVICE_SERIAL"

      wait_for_android_boot

      return 0
    fi

    fail "ADB_SERIAL '$ADB_SERIAL' tidak ditemukan."
  fi

  local devices=()

  mapfile -t devices < <(
    connected_devices
  )

  if [[ "${#devices[@]}" -eq 0 ]]; then
    start_emulator
    return 0
  fi

  local device

  for device in "${devices[@]}"; do
    if [[ "$device" == emulator-* ]]; then
      DEVICE_SERIAL="$device"
      break
    fi
  done

  if [[ -z "$DEVICE_SERIAL" ]]; then
    DEVICE_SERIAL="${devices[0]}"
  fi

  success "Device dipilih: $DEVICE_SERIAL"

  wait_for_android_boot
}

reverse_api() {
  step "Menghubungkan emulator ke backend localhost"

  "$ADB_BIN" \
    -s "$DEVICE_SERIAL" \
    reverse \
    --remove \
    "tcp:$API_PORT" \
    >/dev/null \
    2>&1 ||
    true

  "$ADB_BIN" \
    -s "$DEVICE_SERIAL" \
    reverse \
    "tcp:$API_PORT" \
    "tcp:$API_PORT"

  success "ADB reverse tcp:$API_PORT aktif"
}

install_apk() {
  if [[ ! -f "$APK_PATH" ]]; then
    fail "APK belum tersedia: $APK_PATH"
  fi

  step "Install APK ke $DEVICE_SERIAL"

  "$ADB_BIN" \
    -s "$DEVICE_SERIAL" \
    install \
    -r \
    "$APK_PATH"

  success "APK terpasang"
}

restart_app() {
  step "Restart aplikasi"

  "$ADB_BIN" \
    -s "$DEVICE_SERIAL" \
    shell am force-stop \
    "$APP_ID"

  "$ADB_BIN" \
    -s "$DEVICE_SERIAL" \
    shell am start \
    -n "$APP_ID/$MAIN_ACTIVITY"

  success "Aplikasi dibuka"
}

show_summary() {
  printf '\n'
  printf '============================================\n'
  printf ' E-Absensi development selesai\n'
  printf '============================================\n'
  printf 'Device : %s\n' "$DEVICE_SERIAL"
  printf 'API    : %s\n' "$API_BASE_URL"
  printf 'APK    : %s\n' "$APK_PATH"
  printf '============================================\n'
}

command_android() {
  check_requirements

  start_services

  validate_flutter

  build_apk

  select_device

  reverse_api

  install_apk

  restart_app

  show_summary
}

command_check() {
  check_requirements

  compose up -d flutter

  validate_flutter
}

command_build() {
  check_requirements

  start_services

  validate_flutter

  build_apk
}

command_install() {
  check_requirements

  select_device

  reverse_api

  install_apk

  restart_app

  show_summary
}

command_up() {
  check_requirements

  start_services

  compose ps
}

command_backend() {
  check_requirements

  step "Menyalakan database"

  compose up -d db

  step "Build backend"

  compose build backend

  step "Recreate backend"

  compose up -d \
    --force-recreate \
    backend

  wait_backend

  compose ps
}

command_doctor() {
  check_requirements

  printf '\n'
  printf 'Docker Compose:\n'
  compose ps || true

  printf '\n'
  printf 'Backend health:\n'

  if curl -fsS "$HEALTH_URL"; then
    printf '\n'
  else
    printf 'Backend tidak dapat dihubungi.\n'
  fi

  printf '\n'
  printf 'ADB:\n'
  printf '%s\n' "$ADB_BIN"

  "$ADB_BIN" start-server >/dev/null 2>&1 ||
    true

  "$ADB_BIN" devices -l || true

  printf '\n'
  printf 'AVD:\n'

  if [[ -n "$EMULATOR_BIN" ]]; then
    "$EMULATOR_BIN" -list-avds || true
  else
    printf 'Android Emulator tidak ditemukan.\n'
  fi

  printf '\n'
  printf 'APK:\n'

  if [[ -f "$APK_PATH" ]]; then
    ls -lh "$APK_PATH"
  else
    printf 'APK belum tersedia.\n'
  fi
}

show_help() {
  cat <<'EOF'
E-Absensi Development Runner

Penggunaan:

  bash dev.sh
  bash dev.sh android
      Jalankan seluruh proses:
      Docker -> pub get -> format -> analyze -> test
      -> build APK -> ADB reverse -> install -> restart app.

  bash dev.sh check
      pub get -> format -> analyze -> test.

  bash dev.sh build
      Validasi Flutter dan build APK.

  bash dev.sh install
      Install APK yang sudah ada dan buka aplikasi.

  bash dev.sh up
      Jalankan Docker services.

  bash dev.sh backend
      Rebuild dan recreate backend.

  bash dev.sh doctor
      Cek Docker, backend, ADB, emulator, dan APK.

Environment opsional:

  API_PORT=8080
  API_BASE_URL=http://127.0.0.1:8080

  AVD_NAME=Pixel_9_Pro
  CAMERA_BACK=webcam0

  ADB_SERIAL=emulator-5554

  AUTO_START_EMULATOR=0

Contoh:

  AVD_NAME=Pixel_9_Pro bash dev.sh

  CAMERA_BACK=webcam0 bash dev.sh

  ADB_SERIAL=emulator-5554 bash dev.sh install
EOF
}

case "${1:-android}" in
  android)
    command_android
    ;;

  check)
    command_check
    ;;

  build)
    command_build
    ;;

  install)
    command_install
    ;;

  up)
    command_up
    ;;

  backend)
    command_backend
    ;;

  doctor)
    command_doctor
    ;;

  help | --help | -h)
    show_help
    ;;

  *)
    printf 'Perintah tidak dikenal: %s\n\n' "$1"

    show_help

    exit 1
    ;;
esac