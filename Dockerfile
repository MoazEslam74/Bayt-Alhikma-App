FROM ghcr.io/cirruslabs/flutter:3.41.5 AS build
WORKDIR /app

# حل مشكلة Git
RUN git config --global --add safe.directory /sdks/flutter

# نسخ الكود (اللي اتأكدنا إنه وصل 256MB)
COPY . .

# الموافقة على الرخص
RUN yes | flutter doctor --android-licenses || true

RUN flutter pub get

ARG GOOGLE_API_KEY
ARG SEARCH_ENGINE_ID

# هنستخدم --verbose عشان يطبع كل حرف بيحصل ويقولنا ليه بيفشل فوراً
RUN flutter build apk --release -v \
    --dart-define=GOOGLE_API_KEY=${GOOGLE_API_KEY} \
    --dart-define=SEARCH_ENGINE_ID=${SEARCH_ENGINE_ID}