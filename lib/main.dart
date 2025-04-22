
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notesapp/bloc/editor/editor_bloc.dart';
import 'dart:io';

import 'package:notesapp/bloc/file_browser/file_browser_bloc.dart';
import 'package:notesapp/pages/main_page/main_page.dart'; // Import dart:io

void main() {
  WidgetsFlutterBinding.ensureInitialized();


  String initialPath = '.'; // Default path
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
     initialPath = Directory.current.path;
  } else {
    // mobile and web support might be worked on later
  }


  runApp(MyApp(initialPath: initialPath));
}

class MyApp extends StatelessWidget {
  final String initialPath;

  const MyApp({super.key, required this.initialPath});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FileBrowserBloc>(
          create: (context) => FileBrowserBloc()..add(LoadDirectory(initialPath)),
        ),
        BlocProvider<EditorBloc>(
          create: (context) => EditorBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Markdown Editor',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
