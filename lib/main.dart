import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notesapp/bloc/editor/editor_bloc.dart';
import 'dart:io';

import 'package:notesapp/bloc/file_browser/file_browser_bloc.dart';
import 'package:notesapp/bloc/user_settings/user_settings_cubit.dart';
import 'package:notesapp/misc/app_themes.dart';
import 'package:notesapp/misc/user_settings.dart';
import 'package:notesapp/pages/main_page/main_page.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import dart:io

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  String initialPath = '.'; // Default path
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    initialPath = Directory.current.path;
  } else {
    // mobile and web support might be worked on later
  }

  runApp(AsteriskEditor(initialPath: initialPath, prefs: prefs));
}

class AsteriskEditor extends StatelessWidget {
  final String initialPath;
  final SharedPreferences prefs;

  const AsteriskEditor({
    super.key,
    required this.initialPath,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {

    return MultiBlocProvider(
      providers: [
        BlocProvider<FileBrowserBloc>(
          create:
              (context) => FileBrowserBloc()..add(LoadDirectory(initialPath)),
        ),
        BlocProvider<EditorBloc>(create: (context) => EditorBloc()),
        BlocProvider<UserSettingsCubit>(
          create: (_) => UserSettingsCubit(prefs),
        ),
      ],
      child: BlocBuilder<UserSettingsCubit, UserSettings>(
        builder: (context, settings) {
          return MaterialApp(
            title: 'Asterisk Editor',
            home: const HomePage(),
            theme: AppThemes.light,
            darkTheme: AppThemes.dark,
            
            themeMode: settings.themeMode, // <-- now defined
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

var themeData = ThemeData(
  fontFamily: 'Raleway',
  primaryColor: Colors.blue,
  brightness: Brightness.light,
);
