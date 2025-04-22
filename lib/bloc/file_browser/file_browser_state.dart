part of 'file_browser_bloc.dart';

abstract class FileBrowserState extends Equatable {
  const FileBrowserState();

  @override
  List<Object?> get props => [];
}

class FileBrowserInitial extends FileBrowserState {}

class FileBrowserLoading extends FileBrowserState {}

class FileBrowserLoaded extends FileBrowserState {
  final String currentPath;
  final List<FileSystemEntity> entities; // Contains Files and Directories
  final File? selectedFile;

  const FileBrowserLoaded({
    required this.currentPath,
    required this.entities,
    this.selectedFile,
  });

  @override
  List<Object?> get props => [currentPath, entities, selectedFile];

  FileBrowserLoaded copyWith({
    String? currentPath,
    List<FileSystemEntity>? entities,
    File? selectedFile,
    bool forceSelectedNull = false, // Helper to explicitly clear selection
  }) {
    return FileBrowserLoaded(
      currentPath: currentPath ?? this.currentPath,
      entities: entities ?? this.entities,
      // If forceSelectedNull is true, set to null, otherwise update or keep existing
      selectedFile: forceSelectedNull ? null : (selectedFile ?? this.selectedFile),
    );
  }
}

class FileBrowserError extends FileBrowserState {
  final String message;

  const FileBrowserError(this.message);

  @override
  List<Object> get props => [message];
}