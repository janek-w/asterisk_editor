import 'package:flutter/material.dart';

class EditingPaneWidget extends StatelessWidget {
  const EditingPaneWidget({
    super.key,
    required ScrollController editorScrollController,
    required TextEditingController textEditingController,
  }) : _editorScrollController = editorScrollController, _textEditingController = textEditingController;

  final ScrollController _editorScrollController;
  final TextEditingController _textEditingController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Scrollbar(
              controller: _editorScrollController,
              thumbVisibility: true,
              child: TextField(
                controller: _textEditingController,
                scrollController: _editorScrollController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration( /* ... */ ),
                style: const TextStyle( /* ... */ ),
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}