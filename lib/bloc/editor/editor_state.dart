part of 'editor_bloc.dart';

abstract class EditorState extends Equatable {
  const EditorState();

  @override
  List<Object?> get props => [];
}

class EditorInitial extends EditorState {
  const EditorInitial();
}

class EditorLoading extends EditorState {
   const EditorLoading();
}

class EditorLoaded extends EditorState {
  final File currentFile;
  final String content;
  final bool isDirty; // Has unsaved changes

  const EditorLoaded({
    required this.currentFile,
    required this.content,
    this.isDirty = false,
  });

  @override
  List<Object?> get props => [currentFile.path, content, isDirty]; // Use path for comparison

  EditorLoaded copyWith({
    File? currentFile,
    String? content,
    bool? isDirty,
  }) {
    return EditorLoaded(
      currentFile: currentFile ?? this.currentFile,
      content: content ?? this.content,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

class EditorSaving extends EditorState {
   final File fileBeingSaved;
   const EditorSaving(this.fileBeingSaved);
    @override
  List<Object?> get props => [fileBeingSaved.path];
}


class EditorSaveSuccess extends EditorState {
  final File savedFile;
  const EditorSaveSuccess(this.savedFile);
   @override
  List<Object?> get props => [savedFile.path];
}


class EditorError extends EditorState {
  final String message;
  final File? fileAttempted; // Keep track of which file caused the error

  const EditorError(this.message, {this.fileAttempted});

  @override
  List<Object?> get props => [message, fileAttempted?.path];
}