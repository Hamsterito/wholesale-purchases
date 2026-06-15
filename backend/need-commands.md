# Команды для настройки Android Emulator

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
