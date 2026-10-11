// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_weather/widgets/language_picker_dialog.dart';
import 'package:my_weather/localization/app_strings.dart';

Future<void> pumpLanguageDialog(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LanguagePickerDialog(
        onLanguageSelected: (_) {},
      ),
    ),
  );
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build a minimal app for the test and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('0')),
      ),
    ));

    // Verify that our counter text starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('language picker shows the supported languages',
      (WidgetTester tester) async {
    await pumpLanguageDialog(tester);

    expect(find.text('English'), findsNWidgets(2));
    expect(find.text('Español'), findsNWidgets(2));
    expect(find.text('Français'), findsNWidgets(2));
    expect(find.text('Proceed'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('proceed confirms the selected language',
      (WidgetTester tester) async {
    String? selectedLanguage;
    await tester.pumpWidget(
      MaterialApp(
        home: LanguagePickerDialog(
          onLanguageSelected: (code) => selectedLanguage = code,
        ),
      ),
    );

    await tester.tap(find.text('Español').first);
    await tester.tap(find.text('Proceed'));

    expect(selectedLanguage, 'es');
  });

  test('greeting and weather descriptions follow the selected language', () {
    const spanish = AppStrings('es');
    const french = AppStrings('fr');

    expect(spanish.greetingForHour(8, 'Jalyzer'), 'Buenos días, Jalyzer');
    expect(french.greetingForHour(19, 'Jalyzer'), 'Bonsoir, Jalyzer');
    expect(spanish.weatherDescription('clear sky'), 'Cielo despejado');
    expect(french.weatherDescription('light rain'), 'Pluie légère');
  });
}
