import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class FileListItem extends StatelessWidget {
  final FileSystemEntity entity;
  final String currentPath; // Needed to identify the ".." entry
  final bool isSelected;
  final VoidCallback onTap;

  const FileListItem({
    super.key,
    required this.entity,
    required this.currentPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isDirectory = entity is Directory;
    bool isParentLink = isDirectory && entity.path != currentPath && p.dirname(currentPath) == entity.path;

    IconData iconData;
    String name;

    if (isParentLink) {
      iconData = Icons.arrow_upward;
      name = '..';
    } else if (isDirectory) {
      iconData = Icons.folder;
      name = p.basename(entity.path);
    } else { // It's a file
      iconData = Icons.insert_drive_file_outlined;
      name = p.basename(entity.path);
    }

    return ListTile(
      leading: Icon(iconData, size: 20),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.2),
      dense: true,
      onTap: onTap,
    );
  }
}