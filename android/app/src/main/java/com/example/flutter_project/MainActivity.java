package com.example.flutter_project;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import com.yandex.mapkit.MapKitFactory;

public class MainActivity extends FlutterActivity {
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        MapKitFactory.setLocale("ru_RU");
        MapKitFactory.setApiKey("a009e91e-439f-4c18-80a6-b85d1ab0f253");
        super.configureFlutterEngine(flutterEngine);
    }
}
