# Asterisk

A modern, cross-platform **Markdown editor** built with Flutter, featuring Typora-style WYSIWYG editing with live syntax rendering.

![Flutter](https://img.shields.io/badge/Flutter-3.8+-02569B?logo=flutter)
![Platforms](https://img.shields.io/badge/Platforms-Windows%20|%20macOS%20|%20Linux-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

### Editor Modes
- **WYSIWYG Mode** — Live rendering
- **Raw Markdown Mode** — Plain text editing
- **Preview Mode** — Full rendered markdown preview
- **Split Panes** — Resizable editor panes with live rendering

### Full Markdown Support
| Block Elements | Inline Elements |
|----------------|-----------------|
| Headers (H1-H6) | **Bold**, *Italic*, ~~Strikethrough~~ |
| Fenced code blocks | `Inline code` |
| Blockquotes | [Links](url) |
| Ordered & unordered lists | ![Images](url) |
| Task lists `- [x]` | Math: `$E=mc^2$` |
| Tables | ==Highlight==, ~sub~, ^super^ |
| Horizontal rules | :emoji: shortcodes |
| Math blocks `$$...$$` | Footnotes `[^1]` |


## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.8 or later
- Desktop development enabled for your platform

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/asterisk.git
cd asterisk/asterisk_editor

# Install dependencies
flutter pub get

# Run the application
flutter run -d linux    # or: -d windows, -d macos
```

## Project Structure

```
asterisk_editor/
├── lib/
│   ├── bloc/           # State management (BLoC pattern)
│   ├── config/         # App configuration & theme
│   ├── pages/          # Main UI screens
│   │   ├── main_page/  # Editor with file browser & panes
│   │   └── settings_page/
│   ├── services/       # Core services
│   │   ├── markdown_parser.dart    # Markdown tokenization
│   │   └── text_span_renderer.dart # Token → styled TextSpan
│   └── widgets/        # Reusable UI components
├── test/               # Unit tests
└── pubspec.yaml
```

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management |
| `markdown_widget` | Markdown preview rendering |
| `multi_split_view` | Resizable editor panes |
| `shared_preferences` | Settings persistence |
| `google_fonts` | Typography |



## Markdown Syntax Reference

### Basic Formatting
```markdown
**bold** or __bold__
*italic* or _italic_
~~strikethrough~~
==highlighted==
`inline code`
```

### Extended Syntax
```markdown
# Heading 1
## Heading 2

- Unordered list
1. Ordered list
- [x] Task list item

> Blockquote

$E = mc^2$           (inline math)
$$                   (block math)
\sum_{i=0}^n i^2
$$

:smile: :rocket:     (emoji shortcodes)
H~2~O               (subscript)
x^2^                (superscript)
[^1]                (footnote)
```

## License

This project is licensed under the MIT License.

---

Made with ❤️ and Flutter