# Developer Guide

Welcome to the Asterisk developer documentation! This guide will help you understand the project structure, architecture, and core concepts needed to contribute to the codebase.

## Project Structure

The project follows a standard Flutter feature-based structure:

```
asterisk_editor/
├── lib/
│   ├── bloc/           # Global state management (EditorBloc, ThemeBloc)
│   ├── config/         # App configuration, themes, and constants
│   ├── misc/           # Utilities and helpers
│   ├── pages/          # UI Screens
│   │   ├── main_page/  # The core editor UI (Split panes, file tree)
│   │   └── settings_page/
│   ├── services/       # Core business logic (Parsing, Rendering, IO)
│   └── widgets/        # Shared UI components
```

## Architecture Overview

Asterisk uses the **BLoC (Business Logic Component)** pattern for state management.

### Key Components

1.  **EditorBloc**: The central brain of the application. It manages:
    *   The currently open file and its content.
    *   File system operations (save, load).
    *   Editor state (dirty flags, cursor position).
2.  **Services**: implementation of complex logic decoupled from UI.
    *   `MarkdownParser`: Regex-based parser transforming text to tokens.
    *   `TextSpanRenderer`: Converts tokens to Flutter `TextSpan`s.
    *   `FileService` (implied): Handles disk I/O.

## State Management

We use `flutter_bloc` for state management. Events are dispatched from the UI (e.g., `EditorTextChanged`, `FileOpened`), processed by the Bloc, which then emits new States (e.g., `EditorLoaded`, `EditorError`) that the UI rebuilds to reflect.

## Theme System

The app supports a flexible theming system defined in `lib/config/themes.dart` (or similar). Themes control not just the UI colors but also the syntax highlighting in the editor.

## Key Libraries

*   `flutter_bloc`: State management.
*   `multi_split_view`: For the resizable pane layout.
*   `markdown_widget`: Used for the static "Preview Mode".

## Next Steps

If you are looking to understand how the WYSIWYG editor works, check out the [WYSIWYG Editor Internals](WYSIWYG_EDITOR.md) guide.
