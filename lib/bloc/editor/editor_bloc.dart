import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/logger.dart';

part 'editor_event.dart';
part 'editor_state.dart';

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  final TaggedAppLogger _logger = AppLogger().withTag('EditorBloc');
  String _originalContent = '';

  EditorBloc() : super(const EditorInitial()) {
    on<LoadFileRequested>(_onLoadFileRequested);
    on<ContentChanged>(_onContentChanged);
    on<SaveFileRequested>(_onSaveFileRequested);
    on<ToggleEditorMode>(_onToggleEditorMode);
  }

  Future<void> _onLoadFileRequested(
      LoadFileRequested event, Emitter<EditorState> emit) async {

    // Add check for unsaved changes before loading a new file
    if (state is EditorLoaded && (state as EditorLoaded).isDirty) {
      emit(EditorError("Unsaved changes in the current file.", fileAttempted: (state as EditorLoaded).currentFile));
      _logger.warning("Cannot load ${event.file.path}. Unsaved changes exist.");
      return; // Prevent loading the new file until user confirms
    }


    emit(const EditorLoading());
    try {
       // Check if file exists before trying to read
      if (!await event.file.exists()) {
        emit(EditorError("File not found: ${event.file.path}", fileAttempted: event.file));
        return;
      }
      final content = await event.file.readAsString();
      _originalContent = content; // Store original content
      emit(EditorLoaded(
        currentFile: event.file,
        content: content,
        isDirty: false, // Freshly loaded, not dirty
      ));
    } catch (e) {
      emit(EditorError("Failed to read file: ${e.toString()}", fileAttempted: event.file));
    }
  }

  void _onContentChanged(ContentChanged event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final bool isNowDirty = event.newContent != _originalContent;

      // Only emit if content or dirty status actually changes
      if (currentState.content != event.newContent || currentState.isDirty != isNowDirty) {
         emit(currentState.copyWith(
          content: event.newContent,
          isDirty: isNowDirty,
        ));
      }
    }
     // Debouncing: If performance becomes an issue with large files/fast typing,
     // we could introduce debouncing here before emitting the state.
     // Example using a simple Timer (add `import 'dart:async';`):
     /*
     _debounceTimer?.cancel();
     _debounceTimer = Timer(const Duration(milliseconds: 300), () {
       if (state is EditorLoaded) {
         // ... emit logic as above ...
       }
     });
     */
     // Don't forget to declare `Timer? _debounceTimer;` in the Bloc
     // and cancel it in the Bloc's `close()` method:
     /*
     @override
     Future<void> close() {
       _debounceTimer?.cancel();
       return super.close();
     }
     */
  }

   Future<void> _onSaveFileRequested(
      SaveFileRequested event, Emitter<EditorState> emit) async {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final fileToSave = currentState.currentFile;
      final contentToSave = currentState.content;

      emit(EditorSaving(fileToSave)); // Indicate saving is in progress

      try {
        // Perform save operation asynchronously
        await fileToSave.writeAsString(contentToSave);
        _originalContent = contentToSave; // Update original content on successful save

        emit(currentState.copyWith(isDirty: false));
        
      } catch (e) {
        emit(EditorError("Failed to save file: ${e.toString()}", fileAttempted: fileToSave));
        // Optionally revert state back to EditorLoaded with isDirty: true
        // emit(currentState.copyWith(isDirty: true));
      }
    } else {
      // Cannot save if no file is loaded
      emit(const EditorError("No file loaded to save."));
    }
   }

  void _onToggleEditorMode(
    ToggleEditorMode event,
    Emitter<EditorState> emit,
  ) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      emit(currentState.copyWith(editorMode: event.mode));
    }
  }
}