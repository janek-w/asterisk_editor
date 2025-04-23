import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notesapp/bloc/editor/editor_bloc.dart';
import 'package:notesapp/pages/main_page/panes/editing_pane.dart';
import 'package:notesapp/pages/main_page/panes/file_browser_pane.dart';
import 'package:notesapp/pages/main_page/panes/preview_pane.dart';
import 'package:notesapp/pages/settings_page/settings_page.dart';
import 'package:path/path.dart' as p;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:multi_split_view/multi_split_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _editorScrollController = ScrollController();
  final ScrollController _previewScrollController = ScrollController();
  late MultiSplitViewController _splitViewController;
  final List<String> selectableModes = [
    'Split Pane',
    'Plain Editor',
    'Preview Only',
  ];
  String selectedMode = 'Split Pane';

  File? _currentlyEditingFile;

  @override
  void initState() {
    super.initState();
    // Listen to EditorBloc to update TextField when file loads or changes externally
    context.read<EditorBloc>().stream.listen((state) {
      // --- Logic to update TextField from Bloc State (e.g., on file load) ---
      if (state is EditorLoaded) {
        // Check if the update is necessary (content differs)
        // This prevents unnecessary updates when the change originated from the TextField itself
        if (mounted && _textEditingController.text != state.content) {
          // Store current cursor position
          final currentSelection = _textEditingController.selection;
          _textEditingController.text = state.content;
          // Try to restore cursor position (might jump if text length changed drastically)
          try {
            _textEditingController.selection = currentSelection.copyWith(
              baseOffset: currentSelection.baseOffset.clamp(
                0,
                _textEditingController.text.length,
              ),
              extentOffset: currentSelection.extentOffset.clamp(
                0,
                _textEditingController.text.length,
              ),
            );
          } catch (e) {
            // Handle potential range errors if selection is invalid after text change
            _textEditingController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textEditingController.text.length),
            );
          }
        }
        // Keep track of the file
        _currentlyEditingFile = state.currentFile;
      } else if (state is EditorInitial || state is EditorLoading) {
        // Clear field if no file is loaded or loading
        if (mounted) {
          _textEditingController.clear();
          _currentlyEditingFile = null;
        }
      }
    });

    // Listen to TextField changes and notify EditorBloc
    _textEditingController.addListener(() {
      final currentState = context.read<EditorBloc>().state;
      // Only notify if a file is loaded AND the text actually changed
      if (currentState is EditorLoaded &&
          currentState.content != _textEditingController.text) {
        context.read<EditorBloc>().add(
          ContentChanged(_textEditingController.text),
        );
      }
    });
  }

  @override
  void dispose() {
    _splitViewController.dispose();
    _textEditingController.dispose();
    _editorScrollController.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget fileBrowserPane = FileBrowserPaneWidget();
    Widget editorPane = EditingPaneWidget(
      editorScrollController: _editorScrollController,
      textEditingController: _textEditingController,
    );
    Widget previewPane = PreviewPaneWidget(
      previewScrollController: _previewScrollController,
    );

    _splitViewController = MultiSplitViewController(
      areas: 
      (selectedMode == 'Split Pane') ? [
        Area(builder: (context, area) => fileBrowserPane, flex: 0.2, min: 0.1),
        Area(builder: (context, area) => editorPane, flex: 0.4, min: 0.1),
        Area(builder: (context, area) => previewPane, flex: 0.4, min: 0.1),
      ] : (selectedMode == 'Plain Editor') ? [
        Area(builder: (context, area) => fileBrowserPane, flex: 0.2, min: 0.1),
        Area(builder: (context, area) => editorPane, flex: 0.8, min: 0.1),
      ] : [
        Area(builder: (context, area) => fileBrowserPane, flex: 0.2, min: 0.1),
        Area(builder: (context, area) => previewPane, flex: 0.8, min: 0.1),
      ]
    );

    return Scaffold(
      // Use BlocBuilder specifically for AppBar title and actions
      appBar: AppBar(
        // Title based on EditorBloc state
        title: BlocBuilder<EditorBloc, EditorState>(
          builder: (context, state) {
            String windowTitle = "Markdown Editor";
            if (state is EditorLoaded) {
              windowTitle = p.basename(state.currentFile.path);
              if (state.isDirty) {
                windowTitle += " *";
              }
            } else if (state is EditorLoading) {
              windowTitle = "Loading...";
            } else if (state is EditorSaving) {
              windowTitle = "Saving...";
            }
            // Add other states if needed (e.g., EditorSaveSuccess)
            return Text(windowTitle);
          },
        ),
        // Actions based on EditorBloc state
        actions: [
          BlocBuilder<EditorBloc, EditorState>(
            builder: (context, state) {
              // Build a list of actions based on the current state
              List<Widget> currentActions = [];

              // Show Save button if loaded and dirty
              if (state is EditorLoaded && state.isDirty) {
                currentActions.add(
                  IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: 'Save File (Ctrl+S)',
                    onPressed: () {
                      context.read<EditorBloc>().add(SaveFileRequested());
                    },
                  ),
                );
              }
              // Show saving indicator
              if (state is EditorSaving) {
                currentActions.add(
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ), // Adjust padding
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              currentActions.add(
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              );
              currentActions.add(
                DropdownButton2(
                  value: selectedMode,
                  items: selectableModes.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMode = value as String;
                    });
                  },
                  hint: const Text('Actions'),
                ),
              );
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: currentActions,
              );
            },
          ),
        ],
      ),
      body: Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyS, control: true):
            SaveFile(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SaveFile: CallbackAction<SaveFile>(
            onInvoke:
                (SaveFile) => setState(() {
                  //Todo: save file
                  context.read<EditorBloc>().add(SaveFileRequested());
                }),
          ),
        },
        child: MultiSplitView(
          axis: Axis.horizontal,
          controller: _splitViewController,
          pushDividers: true,
          dividerBuilder: (
            axis,
            index,
            resizable,
            dragging,
            highlighted,
            themeData,
          ) {
            return Divider(
              color:
                  highlighted ? Colors.blue : const Color.fromARGB(255, 0, 0, 0),
              thickness: 50,
              indent: 3,
              height: 1,
              endIndent: 3,
            );
          },
          // minimalWeight: 0.1,
          // minimalSize: 150,
        ),
      ),
    ),
    );
  }
}

class SaveFile extends Intent {
  const SaveFile();
}