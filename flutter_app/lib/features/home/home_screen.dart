import 'package:flutter/material.dart';
import '../notes/notes_list_screen.dart';

/// HomeScreen is now an alias for NotesListScreen.
/// Kept so any deep-links or existing routes pointing to '/home' still work.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotesListScreen();
  }
}
