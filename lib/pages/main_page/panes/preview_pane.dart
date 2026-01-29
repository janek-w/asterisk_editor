import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:asterisk_editor/bloc/editor/editor_bloc.dart';

class PreviewPaneWidget extends StatelessWidget {
  const PreviewPaneWidget({
    super.key,
    required ScrollController previewScrollController,
  }) : _previewScrollController = previewScrollController;

  final ScrollController _previewScrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: BlocBuilder<EditorBloc, EditorState>(
        builder: (context, state) {
          if (state is EditorLoaded) {
            return Scrollbar(  
  controller: _previewScrollController,  
  thumbVisibility: true,  
  child: Markdown(
    data: state.content.replaceAll('\n', '&nbsp; \n'),  
    selectable: true,
    controller: _previewScrollController,
    softLineBreak: true,
  ),  
);  
          } else if (state is EditorLoading) {
            return const Center(child: Text("Loading preview..."));
          } else if (state is EditorError) {
            return Center(child: Text("Preview Error: ${state.message}"));
          }
          return const Center(child: Text("Select a Markdown file to preview"));
        },
      ),
    );
  }
}