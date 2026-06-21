# Команды для настройки Android Emulator, Docker и Flutter

## Принимаем лицензии (автоматически)

```bash
echo y | sdkmanager --licenses
```

## Устанавливаем эмулятор и образ системы (x86_64)

```bash
sdkmanager "emulator" "platform-tools" "system-images;android-34;google_apis;x86_64"
```

## Создаём эмулятор Pixel 7 (x86_64)

```bash
avdmanager create avd -n Pixel7 -k "system-images;android-34;google_apis;x86_64" -d pixel_7 -f
```

## Запускаем эмулятор

```bash
emulator -avd Pixel7

emulator -avd Pixel7 -gpu host -memory 4096 -no-snapshot-load
```

```bash
emulator -avd Tecno_Pova_5

emulator -avd Tecno_Pova_5 -gpu host -memory 4096 -no-snapshot-load
```

---

## Запуск и управление Docker

### Сборка и запуск контейнеров (БД + Бэкенд)

```bash
# Запуск контейнеров в фоновом режиме
docker compose up -d

# Сборка образов и запуск контейнеров
docker compose up --build

# Запуск контейнеров с выводом логов в терминал
docker compose up
```

### Просмотр состояния и логов

```bash
# Просмотр запущенных контейнеров
docker compose ps

# Просмотр логов всех контейнеров в реальном времени
docker compose logs -f
```

### Остановка и очистка

```bash
# Остановка и удаление контейнеров
docker compose down

# Остановка с удалением всех данных базы данных (очистка volume)
docker compose down -v
```

```bash
# Пересобрать Docker-контейнеры
docker-compose up -d --build backend
```

### Импорт и экспорт данных базы данных

```bash
# Экспорт (дамп) локальной БД в файл (запуск на хосте)
# Укажите путь к pg_dump.exe, если он не прописан в PATH, например:
# & "C:\Program Files\PostgreSQL\17\bin\pg_dump.exe" -U postgres -h localhost -p 5432 -d shop_db -f shop_db_backup.sql
pg_dump -U postgres -h localhost -p 5432 -d shop_db -f shop_db_backup.sql

# Импорт дампа из файла в Docker-контейнер (запуск на хосте)
# Для PowerShell:
Get-Content shop_db_backup.sql | docker exec -i shop_postgres_db psql -U postgres -d shop_db

# Для классической CMD (командной строки):
cmd /c "docker exec -i shop_postgres_db psql -U postgres -d shop_db < shop_db_backup.sql"
```


---

## Запуск и управление Flutter

### Управление зависимостями и генерация кода

```bash
# Получение зависимостей Flutter
flutter pub get

# Очистка кэша сборки (полезно при сбоях сборки)
flutter clean

# Принудительная генерация файлов локализации l10n
flutter gen-l10n
```

### Запуск приложения

```bash
# Просмотр списка доступных устройств
flutter devices

# Запуск приложения на устройстве по умолчанию
flutter run

# Запуск приложения на конкретном устройстве (например, эмуляторе)
flutter run -d <имя_устройства_или_id>

# Запуск в режиме отладки с очисткой кэша ассетов
flutter run --clear-asset-cache
```

### Сборка приложения

```bash
# Сборка установочного APK для Android (release-версия)
flutter build apk --release

# Сборка Android App Bundle (AAB) для публикации в Google Play
flutter build appbundle --release

# Сборка веб-версии приложения
flutter build web --release
```
