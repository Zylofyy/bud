# Budget

A monthly budget tracker for Android, built with Flutter from the
[Budget App UI](https://claude.ai/artifact/VZCi1TD1i4cM2P4CproCf9) design.

This repo also holds [Glass Lab](glass_lab/), a separate Flutter app: the
Liquid Glass Morph Lab's three iOS 26 glass morphs, rebuilt as live shaders.

- **Overview**: how much is left to spend this month (or how far over budget you
  are), a progress ring, the daily allowance for the rest of the month and the
  days left.
- **Monthly budget**: tap the row to edit it in place.
- **Expenses**: newest first. Tap **Edit** (or long-press a row) to select
  expenses, use **Select All** if you like, then **Delete** removes them all at
  once. **Undo** in the message that follows puts them back. Back or **Done**
  leaves selection without deleting anything.
- **Repeat labels**: an expense with the same name and amount as an earlier one
  is marked **2x**, **3x** and so on, in the order they were logged, across all
  months. The first one has no label.
- **Add Expense**: a bottom sheet for the amount, an optional description and
  the date (within the current month). Its **Add Again** list shows earlier
  expenses, one per name and amount; tick as many as you like and they're
  added on the chosen date, along with the typed expense if there is one.

The budget and expenses are saved on the device with `shared_preferences`. The
overview shows the current calendar month; expenses from earlier months are
kept but not counted.

## Run it

Needs the Flutter SDK (3.47 or later) and an Android device or emulator.

```sh
flutter pub get
flutter run
```

Build an APK to install directly:

```sh
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
```

The release build is signed with the debug key. Before publishing to Google
Play, add your own signing config in `android/app/build.gradle.kts`.

## Tests

```sh
flutter analyze
flutter test
```

## Layout

```
lib/
  main.dart                      app entry, loads saved data
  src/
    theme.dart                   colors and text styles from the design
    models.dart                  the Expense model
    format.dart                  money and date formatting, amount input
    budget_store.dart            state, month summary and persistence
    overview_screen.dart         the main screen
    widgets/
      summary_card.dart          left to spend + progress ring
      month_section.dart         monthly budget, daily allowance, days left
      expense_list.dart          expense rows and multi-select Edit mode
      add_expense_sheet.dart     the New Expense sheet
      grouped.dart               card, section header and row building blocks
      stroke_icon.dart           the design's line icons
```
