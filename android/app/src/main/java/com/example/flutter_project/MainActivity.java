package com.example.flutter_project;

import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.core.view.WindowCompat;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import com.yandex.mapkit.MapKitFactory;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // Синхронизация анимации клавиатуры для плавного появления (убирает лаги)
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        super.onCreate(savedInstanceState);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        MapKitFactory.setLocale("ru_RU");
        MapKitFactory.setApiKey("a009e91e-439f-4c18-80a6-b85d1ab0f253");
        super.configureFlutterEngine(flutterEngine);
    }
}
