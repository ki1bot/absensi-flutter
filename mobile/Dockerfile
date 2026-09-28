FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG FLUTTER_VERSION=3.47.3
ARG ANDROID_COMMAND_LINE_TOOLS_VERSION=15859902

ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV FLUTTER_HOME=/opt/flutter

ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

RUN apt-get update && apt-get install -y \
    bash \
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

RUN git clone \
    --depth 1 \
    --branch ${FLUTTER_VERSION} \
    https://github.com/flutter/flutter.git \
    ${FLUTTER_HOME}

RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
    && curl -L \
    "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_COMMAND_LINE_TOOLS_VERSION}_latest.zip" \
    -o /tmp/android-command-line-tools.zip \
    && unzip /tmp/android-command-line-tools.zip \
    -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && mv \
    ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools \
    ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm /tmp/android-command-line-tools.zip

RUN yes | sdkmanager --licenses > /dev/null \
    && sdkmanager \
    "platform-tools" \
    "platforms;android-36" \
    "build-tools;36.0.0"

RUN flutter config --no-analytics \
    && dart --disable-analytics \
    && flutter precache --android

RUN flutter doctor -v

WORKDIR /workspace/mobile

CMD ["bash", "-lc", "tail -f /dev/null"]