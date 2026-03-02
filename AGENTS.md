# AGENTS.md - Guidelines for AI Agents

> This file provides guidelines for AI agents working on this repository.

## Project Overview

This is a **Flutter application** (Kumi Note) built with the Very Good CLI. It follows a monorepo structure with local packages (`packages/`).

## Build Commands

```bash
# Run app (development)
flutter run --flavor development --target lib/main_development.dart

# Run app (staging)
flutter run --flavor staging --target lib/main_staging.dart

# Run app (production)
flutter run --flavor production --target lib/main_production.dart
```

## Test Commands

```bash
# Run all tests with coverage
very_good test --coverage --test-randomize-ordering-seed random

# Run tests in a specific directory
flutter test test/journal/

# Run a single test file
flutter test test/journal/cubit/journal_cubit_test.dart

# Run a single test by name
flutter test test/journal/cubit/journal_cubit_test.dart --name "test description"

# View coverage report
genhtml coverage/lcov.info -o coverage/
open coverage/index.html
```

## Lint Commands

```bash
# Analyze Dart code
flutter analyze

# Bloc-specific linting
dart run bloc_tools:bloc lint .

# Format code
dart format .

# Very Good Analysis (runs on CI)
very_good packages get --recursive
```

## Code Generation

```bash
# Generate Isar database code
dart run build_runner build --delete-conflicting-outputs

# Generate localizations
flutter gen-l10n --arb-dir="lib/l10n/arb"
```

## Code Style Guidelines

### General Style

- Follows `very_good_analysis` (see `analysis_options.yaml`)
- No public member API docs required (`public_member_api_docs: false`)
- Maximum line length: 80 characters

### Imports

**Order (must be separated by blank lines):**

```dart
// 1. Dart SDK imports
import 'dart:async';
import 'dart:developer';

// 2. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// 3. Third-party package imports (alphabetical)
import 'package:equatable/equatable.dart';
import 'package:google_fonts/google_fonts.dart';

// 4. Local project imports (alphabetical)
import 'package:kumi_note/journal/cubit/journal_cubit.dart';
import 'package:kumi_note/l10n/l10n.dart';
import 'package:kumi_data_sources/kumi_data_sources.dart';
import 'package:kumi_repository/kumi_repository.dart';

// 5. Relative imports (alphabetical)
import 'home_screen.dart';
import 'widgets/note_card.dart';
```

### Architecture Patterns

**BLoC Pattern:**
- Use `Cubit` for simple state management
- Use `Bloc` for complex state machines with events
- States must extend `Equatable`
- Use `sealed` classes for state hierarchies

```dart
// Good
sealed class JournalState extends Equatable {
  const JournalState();
  @override
  List<Object> get props => [];
}

final class JournalLoaded extends JournalState {
  const JournalLoaded({required this.notes});
  final List<NoteModel> notes;
  @override
  List<Object> get props => [notes];
}
```

### Naming Conventions

- **Files:** `snake_case.dart`
- **Classes:** `PascalCase`
- **Variables/Functions:** `camelCase`
- **Constants:** `kCamelCase` or `UPPER_SNAKE_CASE` for enum-like
- **Private members:** `_leadingUnderscore`

### Error Handling

Use `on Object catch` pattern for generic error catching:

```dart
try {
  await _repository.deleteNote(noteId);
} on Object catch (e) {
  emit(JournalError(message: 'Error: $e'));
}
```

Always cancel stream subscriptions in `close()`:

```dart
@override
Future<void> close() {
  unawaited(_notesSubscription?.cancel());
  return super.close();
}
```

### Widgets

- Use `const` constructors when possible
- Pass `super.key` to parent
- Prefer small, composable widgets

```dart
class JournalPage extends StatelessWidget {
  const JournalPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
```

### Localization

Access via context extension:

```dart
final l10n = context.l10n;
return Text(l10n.counterAppBarTitle);
```

Add strings in `lib/l10n/arb/app_en.arb`:

```json
{
  "helloWorld": "Hello World",
  "@helloWorld": {
    "description": "Hello World Text"
  }
}
```

### Dependencies

- **State Management:** flutter_bloc, bloc
- **Database:** sqlite3, sqlite_vector
- **DI:** via RepositoryProvider/BlocProvider
- **LLM:** tflite_flutter for embeddings

### Testing

```dart
// Test structure
void main() {
  group('JournalCubit', () {
    late JournalCubit cubit;
    
    setUp(() {
      cubit = JournalCubit(repository: mockRepository);
    });
    
    tearDown(() => cubit.close());
    
    blocTest<JournalCubit, JournalState>(
      'emits [JournalLoading, JournalLoaded] when loadNotes is called',
      build: () => cubit,
      act: (cubit) => cubit.loadNotes(),
      expect: () => [
        const JournalLoading(),
        const JournalLoaded(notes: []),
      ],
    );
  });
}
```

## Project Structure

```
lib/
├── main.dart                   # Production entry
├── main_development.dart       # Development entry
├── main_staging.dart           # Staging entry
├── bootstrap.dart              # App initialization
├── core/                       # Theme, colors, styles
├── journal/                    # Journal feature
│   ├── cubit/                  # BLoC components
│   └── view/                   # Screens & widgets
├── insights/                   # Analytics feature
├── kumi_chat/                  # Chat feature
└── l10n/                       # Localization

packages/
├── kumi_data_sources/          # Data layer
└── kumi_repository/            # Repository layer
```

## Important Notes

- **No hard tabs** - use 2 spaces for indentation
- **Never commit secrets** - use environment configuration
- Run `flutter analyze` before committing
- CI runs: flutter_package workflow with bloc_lint enabled
