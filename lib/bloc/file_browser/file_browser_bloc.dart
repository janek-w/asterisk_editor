import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;
import '../../services/logger.dart';

part 'file_browser_event.dart';
part 'file_browser_state.dart';

class FileBrowserBloc extends Bloc<FileBrowserEvent, FileBrowserState> {
  final TaggedAppLogger _logger = AppLogger().withTag('FileBrowser');

  FileBrowserBloc() : super(FileBrowserInitial()) {
    on<LoadDirectory>(_onLoadDirectory);
    on<SelectFile>(_onSelectFile);
  }

  Future<void> _onLoadDirectory(
      LoadDirectory event, Emitter<FileBrowserState> emit) async {
    emit(FileBrowserLoading());
    try {
      final directory = Directory(event.path);
      if (!await directory.exists()) {
        emit(FileBrowserError("Directory not found: ${event.path}"));
        return;
      }

      final List<FileSystemEntity> entities = [];
      final Completer<void> completer = Completer();
      final Stream<FileSystemEntity> lister = directory.list();

      lister.listen(
        (entity) {
          if (p.basename(entity.path).startsWith('.')) return;
          if (entity is File && !entity.path.toLowerCase().endsWith('.md')) return;
          entities.add(entity);
        },
        onError: (e) {
          _logger.error("Error listing directory: $e");
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        onDone: () {
           // Sort: Directories first, then files, alphabetically
           entities.sort((a, b) {
              if (a is Directory && b is File) return -1;
              if (a is File && b is Directory) return 1;
              return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
           });
           final parentPath = p.dirname(event.path);
           if (parentPath != event.path) { // Avoid adding ".." if already at root
             entities.insert(0, Directory(parentPath));
           }

          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      await completer.future;

      emit(FileBrowserLoaded(
        currentPath: directory.path,
        entities: entities,
        selectedFile: null, // Clear selection when changing directory
      ));
    } catch (e) {
      emit(FileBrowserError("Failed to load directory: ${e.toString()}"));
    }
  }

 void _onSelectFile(SelectFile event, Emitter<FileBrowserState> emit) {
    if (state is FileBrowserLoaded) {
      final currentState = state as FileBrowserLoaded;
      // Check if the file exists in the current list (optional sanity check)
      bool fileExistsInList = currentState.entities.any((entity) => entity is File && entity.path == event.file.path);

      if(fileExistsInList) {
          emit(currentState.copyWith(selectedFile: event.file));
      } else {
          _logger.warning(
            "Selected file ${event.file.path} not found in current directory list ${currentState.currentPath}",
          );
      }
    }
  }
}