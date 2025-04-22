part of 'file_browser_bloc.dart';

abstract class FileBrowserEvent extends Equatable {
  const FileBrowserEvent();

  @override
  List<Object> get props => [];
}

class LoadDirectory extends FileBrowserEvent {
  final String path;

  const LoadDirectory(this.path);

  @override
  List<Object> get props => [path];
}

class SelectFile extends FileBrowserEvent {
  final File file;

  const SelectFile(this.file);

  @override
  List<Object> get props => [file];
}