import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asterisk_editor/bloc/editor/editor_bloc.dart';
import 'dart:io';

import 'package:asterisk_editor/bloc/file_browser/file_browser_bloc.dart';
import 'package:asterisk_editor/bloc/user_settings/user_settings_cubit.dart';
import 'package:asterisk_editor/misc/app_themes.dart';
import 'package:asterisk_editor/misc/user_settings.dart';
import 'package:asterisk_editor/pages/main_page/main_page.dart';
import 'package:asterisk_editor/services/logger.dart';
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

class AsteriskEditor extends StatefulWidget {
  final String initialPath;
  final SharedPreferences prefs;

  const AsteriskEditor({
    super.key,
    required this.initialPath,
    required this.prefs,
  });

  @override
  State<AsteriskEditor> createState() => _AsteriskEditorState();
}

class _AsteriskEditorState extends State<AsteriskEditor>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppLogger().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      AppLogger().dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FileBrowserBloc>(
          create:
              (context) => FileBrowserBloc()..add(LoadDirectory(widget.initialPath)),
        ),
        BlocProvider<EditorBloc>(create: (context) => EditorBloc()),
        BlocProvider<UserSettingsCubit>(
          create: (_) => UserSettingsCubit(widget.prefs),
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

