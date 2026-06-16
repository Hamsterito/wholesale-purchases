# Этап 1: Сборка нативного бинарного файла Dart
FROM dart:stable AS build

WORKDIR /app

# Сначала копируем только конфигурацию зависимостей для кэширования слоев Docker
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

# Копируем исходный код бэкенда
COPY . .

# Получаем зависимости в оффлайн-режиме (так как они уже скачаны) и собираем нативный бинарник
RUN dart pub get --offline
RUN dart compile exe bin/backend.dart -o bin/backend

# Этап 2: Финальный легковесный контейнер для выполнения
FROM debian:bookworm-slim

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем скомпилированный бинарный файл из этапа сборки
COPY --from=build /app/bin/backend /app/bin/backend

# Создаем директорию для загрузки аватарок пользователей
RUN mkdir -p /app/uploads/avatars

# Экспонируем порт бэкенда
EXPOSE 8081

# Точкой входа является скомпилированное приложение
CMD ["/app/bin/backend"]
