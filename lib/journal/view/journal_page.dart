import 'package:flutter/material.dart';

import 'package:kumi_note/journal/view/home_screen.dart';

/// Journal page - Main view for notes and memory management.
///
/// JournalCubit and ChatCubit are provided at the app level
/// via MultiBlocProvider, so no need to create them here.
class JournalPage extends StatelessWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
