import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notesapp/bloc/editor/editor_bloc.dart';
import 'package:notesapp/pages/main_page/panes/editing_pane.dart';
import 'package:notesapp/pages/main_page/panes/wysiwyg_editing_pane.dart';
import 'package:notesapp/pages/main_page/panes/file_browser_pane.dart';
import 'package:notesapp/pages/main_page/panes/preview_pane.dart';
import 'package:notesapp/pages/settings_page/settings_page.dart';
import 'package:path/path.dart' as p;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:multi_split_view/multi_split_view.dart';
import '../../config/app_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Editor view mode enumeration for the main page layout.
///
/// Defines different ways the editor can be displayed:
/// - [splitPane]: Shows file browser, editor, and preview in split view
/// - [plainEditor]: Shows file browser and plain text editor
/// - [wysiwygEditor]: Shows file browser and WYSIWYG markdown editor
/// - [previewOnly]: Shows file browser and preview pane only
enum EditorViewMode {
  splitPane,
  plainEditor,
  wysiwygEditor,
  previewOnly;

  /// Get the display name for this mode
  String get displayName {
    switch (this) {
      case EditorViewMode.splitPane:
        return 'Split Pane';
      case EditorViewMode.plainEditor:
        return 'Plain Editor';
      case EditorViewMode.wysiwygEditor:
        return 'WYSIWYG Editor';
      case EditorViewMode.previewOnly:
        return 'Preview Only';
    }
  }

  /// Get the list of all available modes
  static List<EditorViewMode> get allValues => EditorViewMode.values;

  /// Convert to the corresponding EditorMode enum
  EditorMode toEditorMode() {
    switch (this) {
      case EditorViewMode.splitPane:
        return EditorMode.plain;
      case EditorViewMode.plainEditor:
        return EditorMode.plain;
      case EditorViewMode.wysiwygEditor:
        return EditorMode.wysiwyg;
      case EditorViewMode.previewOnly:
        return EditorMode.preview;
    }
  }
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _editorScrollController = ScrollController();
  final ScrollController _previewScrollController = ScrollController();
  final ScrollController _wysiwygScrollController = ScrollController();
  final FocusNode _wysiwygFocusNode = FocusNode();
  late MultiSplitViewController _splitViewController;

  /// Currently selected editor view mode
  EditorViewMode selectedMode = EditorViewMode.splitPane;

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
    _wysiwygScrollController.dispose();
    _wysiwygFocusNode.dispose();
    super.dispose();
  }

  /// Build the appropriate split view areas based on the selected mode.
  ///
  /// Returns a list of [Area] objects configured with the correct flex values
  /// and widgets for the current [selectedMode].
  List<Area> _buildSplitViewAreas(
    Widget fileBrowserPane,
    Widget editorPane,
    Widget wysiwygPane,
    Widget previewPane,
  ) {
    final fileBrowserArea = Area(
      builder: (context, area) => fileBrowserPane,
      flex: AppConfig.fileBrowserFlex,
      min: AppConfig.splitViewMinWidth,
    );

    switch (selectedMode) {
      case EditorViewMode.splitPane:
        return [
          fileBrowserArea,
          Area(
            builder: (context, area) => editorPane,
            flex: AppConfig.editorPaneFlex,
            min: AppConfig.splitViewMinWidth,
          ),
          Area(
            builder: (context, area) => previewPane,
            flex: AppConfig.previewPaneFlex,
            min: AppConfig.splitViewMinWidth,
          ),
        ];

      case EditorViewMode.plainEditor:
        return [
          fileBrowserArea,
          Area(
            builder: (context, area) => editorPane,
            flex: AppConfig.editorPaneSingleFlex,
            min: AppConfig.splitViewMinWidth,
          ),
        ];

      case EditorViewMode.wysiwygEditor:
        return [
          fileBrowserArea,
          Area(
            builder: (context, area) => wysiwygPane,
            flex: AppConfig.editorPaneSingleFlex,
            min: AppConfig.splitViewMinWidth,
          ),
        ];

      case EditorViewMode.previewOnly:
        return [
          fileBrowserArea,
          Area(
            builder: (context, area) => previewPane,
            flex: AppConfig.previewPaneSingleFlex,
            min: AppConfig.splitViewMinWidth,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget fileBrowserPane = FileBrowserPaneWidget();
    Widget editorPane = EditingPaneWidget(
      editorScrollController: _editorScrollController,
      textEditingController: _textEditingController,
    );
    Widget wysiwygPane = WysiwygEditorWidget(
      controller: _textEditingController,
      scrollController: _wysiwygScrollController,
      focusNode: _wysiwygFocusNode,
    );
    Widget previewPane = PreviewPaneWidget(
      previewScrollController: _previewScrollController,
    );

    _splitViewController = MultiSplitViewController(
      areas: _buildSplitViewAreas(
        fileBrowserPane,
        editorPane,
        wysiwygPane,
        previewPane,
      ),
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
                      horizontal: AppConfig.actionButtonPadding,
                    ),
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
                DropdownButton2<EditorViewMode>(
                  value: selectedMode,
                  items: EditorViewMode.allValues.map((mode) {
                    return DropdownMenuItem<EditorViewMode>(
                      value: mode,
                      child: Text(mode.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedMode = value;
                      });
                      // Notify the Bloc about the mode change
                      context.read<EditorBloc>().add(
                        ToggleEditorMode(value.toEditorMode()),
                      );
                    }
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
              color: highlighted ? Colors.blue : const Color.fromARGB(255, 0, 0, 0),
              thickness: AppConfig.resizableDividerThickness,
              indent: AppConfig.dividerIndent,
              height: AppConfig.dividerThickness,
              endIndent: AppConfig.dividerEndIndent,
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
