import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asterisk_editor/bloc/editor/editor_bloc.dart';
import 'package:asterisk_editor/bloc/file_browser/file_browser_bloc.dart';
import 'package:asterisk_editor/widgets/file_list_item.dart';
import 'package:path/path.dart' as p;

class FileBrowserPaneWidget extends StatelessWidget {
  const FileBrowserPaneWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FileBrowserBloc, FileBrowserState>(
      builder: (context, state) {
        if (state is FileBrowserLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is FileBrowserLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Current: ${state.currentPath}",
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: state.entities.length,
                  itemBuilder: (context, index) {
                    final entity = state.entities[index];
                    final isSelected = state.selectedFile?.path == entity.path;
                    bool isParentLink = entity is Directory &&
                        entity.path != state.currentPath &&
                        p.dirname(state.currentPath) == entity.path;
    
                    return FileListItem(
                      entity: entity,
                      currentPath: state.currentPath,
                      isSelected: isSelected,
                      onTap: () {
                        if (entity is Directory) {
                          context
                              .read<FileBrowserBloc>()
                              .add(LoadDirectory(entity.path));
                        } else if (entity is File) {
                          context
                              .read<FileBrowserBloc>()
                              .add(SelectFile(entity));
                          context
                              .read<EditorBloc>()
                              .add(LoadFileRequested(entity));
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        } else if (state is FileBrowserError) {
          return Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Error: ${state.message}"),
              ));
        }
        return const Center(child: Text("Select a directory"));
      },
    );
  }
}