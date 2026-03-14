import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  static const routeName = '/preferences';

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final List<String> _availableGenres = [
    'Action',
    'Aventure',
    'Comédie',
    'Drame',
    'Fantastique',
    'Science-Fiction',
    'Romance',
    'Mystère',
    'Horreur',
    'Slice of Life',
  ];

  final Set<String> _selectedGenres = {};
  bool _isSaving = false;

  Future<void> _savePreferences() async {
    if (_selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez au moins un genre.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Convert selected genre labels to genreIds attendus par l'API.
      final selectedGenreIds = _selectedGenres.map((genre) {
        final index = _availableGenres.indexOf(genre);
        return index >= 0 ? index + 1 : 0;
      }).where((id) => id > 0).toList();

      await AuthService.instance.setPreferences(selectedGenreIds);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'enregistrer les préférences : ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vos préférences')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sélectionnez les genres que vous aimez afin de recevoir des recommandations personnalisées.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableGenres.map((genre) {
                final selected = _selectedGenres.contains(genre);
                return ChoiceChip(
                  label: Text(genre),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedGenres.add(genre);
                      } else {
                        _selectedGenres.remove(genre);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePreferences,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continuer vers l\'accueil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
