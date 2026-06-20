enum LayoutMode {
  focus,
  gallery,
}

extension LayoutModeX on LayoutMode {
  String get label {
    switch (this) {
      case LayoutMode.focus:
        return 'Focus';
      case LayoutMode.gallery:
        return 'Gallery';
    }
  }
}
