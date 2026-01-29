import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asterisk_editor/bloc/user_settings/user_settings_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<String> _colorThemeOptions = [
    'Light Theme',
    'Dark Theme',
    'System Theme',
  ];
  String _colorTheme = 'Light Theme';
  String _fontSize = 'Medium';

  @override
  void initState() {
    super.initState();
    final mode = context.read<UserSettingsCubit>().state.themeMode;
    if (mode == ThemeMode.light) {
      _colorTheme = 'Light Theme';
    } else if (mode == ThemeMode.dark) {
      _colorTheme = 'Dark Theme';
    } else {
      _colorTheme = 'System Theme';
    }
  }

  void _updateTheme(String newValue) {
    setState(() {
      _colorTheme = newValue;
    });
    if (_colorTheme == 'Light Theme') {
      context.read<UserSettingsCubit>().setTheme(ThemeMode.light);
    } else if (_colorTheme == 'Dark Theme') {
      context.read<UserSettingsCubit>().setTheme(ThemeMode.dark);
    } else {
      context.read<UserSettingsCubit>().setTheme(ThemeMode.system);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('Choose your preferred color mode'),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _colorTheme,
                items: _colorThemeOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _updateTheme(val);
                },
              ),
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Editor'),
          ListTile(
            title: const Text('Font Size'),
            subtitle: const Text('Adjust the editor text size'),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _fontSize,
                items: ['Small', 'Medium', 'Large'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _fontSize = newValue!;
                  });
                },
              ),
            ),
          ),
          // Add more settings here
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
