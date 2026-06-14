import 'dart:io';
import 'dart:convert';

void main() async {
  final filesList = File('hardcoded_files.txt');
  if (!await filesList.exists()) {
    print('hardcoded_files.txt not found!');
    return;
  }

  final arbFile = File('lib/l10n/app_ru.arb');
  Map<String, dynamic> arbData = {};
  if (await arbFile.exists()) {
    arbData = jsonDecode(await arbFile.readAsString());
  }

  int keyCounter = 0;
  String generateKey(String filePath, String content) {
    keyCounter++;
    final baseName = filePath.replaceAll('\\', '/').split('/').last.split('.').first;
    return '${baseName}_auto_$keyCounter';
  }

  final lines = await filesList.readAsLines();
  int totalReplaced = 0;

  for (String filePath in lines) {
    filePath = filePath.trim();
    if (filePath.isEmpty) continue;
    // Normalize path
    filePath = filePath.replaceAll('.\\', '');

    if (filePath.replaceAll('\\', '/').startsWith('lib/l10n/')) {
      print('Skipping localization file: $filePath');
      continue;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      print('File not found: $filePath');
      continue;
    }

    String content = await file.readAsString();
    bool modified = false;

    // We will use a regex to find strings and comments
    // Group 1: Multi-line comments
    // Group 2: Single-line comments
    // Group 3: Raw strings r'...' or r"..."
    // Group 4: Triple quotes '''...''' or """..."""
    // Group 5: Double-quoted strings "..."
    // Group 6: Single-quoted strings '...'
    final RegExp tokenRegex = RegExp(
      r"""(\/\*[\s\S]*?\*\/)|(\/\/[^\n]*)|(r['"].*?['"])|('''[\s\S]*?'''|"{3}[\s\S]*?"{3})|("(?:[^\\"\n]|\\.)*")|('(?:[^\\'\n]|\\.)*')""",
      multiLine: true,
    );

    String newContent = content.replaceAllMapped(tokenRegex, (match) {
      if (match.group(1) != null || match.group(2) != null) {
        // It's a comment, leave it unchanged
        return match.group(0)!;
      }

      String stringToken = match.group(0)!;
      
      // Check if it contains Cyrillic
      if (!RegExp(r'[А-Яа-яЁё]').hasMatch(stringToken)) {
        return stringToken;
      }

      // If it's a string with Cyrillic, we need to extract it
      // Let's get the inner content
      String innerContent = '';
      String quoteType = '';
      if (match.group(5) != null) {
        innerContent = match.group(5)!.substring(1, match.group(5)!.length - 1);
        quoteType = '"';
      } else if (match.group(6) != null) {
        innerContent = match.group(6)!.substring(1, match.group(6)!.length - 1);
        quoteType = "'";
      } else {
        // It's raw or triple quoted string, we skip for safety unless it's easy
        return stringToken; 
      }

      // Check for string interpolation
      if (innerContent.contains('\$')) {
        print('Skipping interpolated string in $filePath: $stringToken');
        return stringToken;
      }

      // Replace escaped characters to standard
      String unescaped = innerContent.replaceAll('\\n', '\n').replaceAll('\\"', '"').replaceAll("\\'", "'");
      
      // Add to ARB
      String newKey = generateKey(filePath, unescaped);
      arbData[newKey] = unescaped;
      arbData['@$newKey'] = {
        'description': 'Auto-extracted from $filePath'
      };

      modified = true;
      totalReplaced++;

      // Return replacement
      return "AppLocalizations.current.getString('$newKey')";
    });

    if (modified) {
      // Ensure import is present
      if (!newContent.contains("app_localizations.dart")) {
        newContent = "import 'package:flutter_project/services/localization/app_localizations.dart';\n" + newContent;
      }
      
      await file.writeAsString(newContent);
      print('Updated $filePath');
    }
  }

  if (totalReplaced > 0) {
    const encoder = JsonEncoder.withIndent('  ');
    await arbFile.writeAsString(encoder.convert(arbData));
    print('Added $totalReplaced strings to app_ru.arb');
  } else {
    print('No hardcoded strings found.');
  }
}
