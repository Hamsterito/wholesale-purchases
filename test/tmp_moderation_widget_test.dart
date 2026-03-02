import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project/moderator/moderation_page.dart';

class _NoNetworkOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _NoNetworkHttpClient();
  }
}

class _NoNetworkHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw const SocketException('No network in test');
  }
}

void main() {
  testWidgets('pump moderation page', (tester) async {
    HttpOverrides.global = _NoNetworkOverrides();
    await tester.pumpWidget(const MaterialApp(home: ModerationPage()));
    await tester.pump(const Duration(milliseconds: 200));
    HttpOverrides.global = null;
  });
}
