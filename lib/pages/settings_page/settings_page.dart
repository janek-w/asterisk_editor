import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notesapp/bloc/user_settings/user_settings_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  final List<String> _coloreThemeOptions = ['Light Theme', 'Dark Theme', 'System Theme'];
  String _colorTheme = 'Light Theme';
  String _fontSize = 'Medium';
  final String _fontFamily = 'Arial';
  final String _lineHeight = '1.5';

  @override
  void initState() {
    _colorTheme = context.read<UserSettingsCubit>().state.themeMode == ThemeMode.light
        ? 'Light Theme'
        : context.read<UserSettingsCubit>().state.themeMode == ThemeMode.dark
            ? 'Dark Theme'
            : 'System Theme';
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 80),
          child: Column(
            children: [
              Text('General Settings'),
              const Divider(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: Text('Color Theme')
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButton<String>(
                      value: _colorTheme,
                      items: _coloreThemeOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _colorTheme = newValue!;
                          if (_colorTheme == 'Light Theme') {
                            context.read<UserSettingsCubit>().setTheme(ThemeMode.light);
                          } else if (_colorTheme == 'Dark Theme') {
                            context.read<UserSettingsCubit>().setTheme(ThemeMode.dark);
                          } else {
                          }
                        });
                      },
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: Text('Font Size')
                  ),
                  SizedBox(
                    width: 200,
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
                  )
                ],
              ),
            ],
          ),
        ),
    )
    );  
  }
}