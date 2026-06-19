part of '../backend.dart';

/// Вспомогательные функции для работы с курсами валют.
///
/// Этот файл содержит логику получения официального курса рубля с сайта
/// Национального Банка Республики Казахстан, парсинга XML регулярными выражениями
/// и периодического обновления в базе данных PostgreSQL.

/// Проверяет и при необходимости обновляет курсы валют.
/// Запрос к сайту Нацбанка РК выполняется только если последняя запись
/// в базе данных старше 24 часов или отсутствует.
Future<void> checkAndUpdateExchangeRates(Connection connection) async {
  try {
    // Проверяем, нужно ли обновление
    final result = await connection.execute(
      Sql.named("SELECT updated_at FROM public.exchange_rates WHERE currency_code = 'RUB';"),
    );

    bool needsUpdate = true;
    if (result.isNotEmpty) {
      final lastUpdate = result.first.toColumnMap()['updated_at'] as DateTime;
      final difference = DateTime.now().difference(lastUpdate);
      if (difference.inHours < 24) {
        needsUpdate = false;
        print('Курсы валют актуальны. Последнее обновление было ${difference.inHours} ч. назад.');
      }
    }

    if (!needsUpdate) return;

    print('Начало обновления курса валют с сайта Нацбанка РК...');
    final rate = await _fetchAndParseExchangeRate();
    if (rate == null) {
      print('Не удалось распарсить курс валюты. Обновление пропущено.');
      return;
    }

    // Обновляем значение курса в базе данных
    await connection.execute(
      Sql.named('''
        INSERT INTO public.exchange_rates (currency_code, rate, updated_at)
        VALUES ('RUB', @rate, NOW())
        ON CONFLICT (currency_code) DO UPDATE
        SET rate = EXCLUDED.rate,
            updated_at = NOW();
      '''),
      parameters: {'rate': rate},
    );
    print('Курс валюты RUB успешно обновлен: 1 KZT = $rate RUB.');
  } catch (e, st) {
    print('Ошибка при обновлении курса валют: $e\n$st');
  }
}

/// Запрашивает XML и извлекает курс RUB относительно KZT.
/// Возвращает стоимость 1 KZT в RUB (обратный курс).
Future<double?> _fetchAndParseExchangeRate() async {
  final client = HttpClient();
  // Устанавливаем тайм-аут соединения в 10 секунд
  client.connectionTimeout = const Duration(seconds: 10);
  
  try {
    final request = await client.getUrl(Uri.parse('https://nationalbank.kz/rss/rates_all.xml'));
    final response = await request.close();
    
    if (response.statusCode != 200) {
      print('Ошибка при запросе к Нацбанку РК: ${response.statusCode}');
      return null;
    }

    final xmlContent = await response.transform(utf8.decoder).join();
    return _parseRubRateFromXml(xmlContent);
  } catch (e) {
    print('Сетевая ошибка при получении курса с сайта Нацбанка РК: $e');
    return null;
  } finally {
    client.close();
  }
}

/// Вырезает блок RUB из XML и рассчитывает обратный курс.
double? _parseRubRateFromXml(String xml) {
  // Находим элемент <item> для RUB (ограничиваем поиск, чтобы не захватить другие элементы)
  final rubItemRegExp = RegExp(r'<item>\s*<title>RUB</title>[\s\S]*?</item>');
  final rubMatch = rubItemRegExp.firstMatch(xml);
  if (rubMatch == null) {
    print('В XML-фиде не найден элемент для валюты RUB.');
    return null;
  }

  final rubXml = rubMatch.group(0)!;

  // Извлекаем номинал (quant) и курс (description)
  final quantRegExp = RegExp(r'<quant>(.*?)</quant>');
  final descriptionRegExp = RegExp(r'<description>(.*?)</description>');

  final quantMatch = quantRegExp.firstMatch(rubXml);
  final descMatch = descriptionRegExp.firstMatch(rubXml);

  if (quantMatch == null || descMatch == null) {
    print('Не удалось найти номинал или курс в XML-блоке RUB.');
    return null;
  }

  final quantStr = quantMatch.group(1)?.trim();
  final descStr = descMatch.group(1)?.trim();

  final quant = double.tryParse(quantStr ?? '');
  final description = double.tryParse(descStr ?? '');

  if (quant == null || description == null || description <= 0 || quant <= 0) {
    print('Ошибка преобразования номинала ($quantStr) или курса ($descStr) в число.');
    return null;
  }

  // Расчет обратного курса: сколько рублей дают за 1 тенге (1 KZT = Y RUB)
  // Нацбанк возвращает: за quant рублей дают description тенге.
  // То есть 1 RUB = description / quant тенге.
  // Соответственно 1 KZT = quant / description рублей.
  return quant / description;
}
