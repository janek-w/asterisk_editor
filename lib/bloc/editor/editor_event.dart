
part of 'editor_bloc.dart';

abstract class EditorEvent extends Equatable {
  const EditorEvent();

  @override
  List<Object> get props => [];
}

class LoadFileRequested extends EditorEvent {
  final File file;

  const LoadFileRequested(this.file);

  @override
  List<Object> get props => [file];
}

class ContentChanged extends EditorEvent {
  final String newContent;

  const ContentChanged(this.newContent);

  @override
  List<Object> get props => [newContent];
}

class SaveFileRequested extends EditorEvent {} // Add parameters if needed (e.g., path)
