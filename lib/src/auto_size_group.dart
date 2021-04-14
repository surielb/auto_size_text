part of auto_size_text;

enum AutoSizeGroupBehavior { smallest, proportional }

class _AutoSizeGroupEntry {
  final double fontSize;
  final double maxFontSize;

  double get proportion => maxFontSize.isInfinite || fontSize.isInfinite
      ? 1
      : maxFontSize / fontSize;
  _AutoSizeGroupEntry(this.fontSize, this.maxFontSize);
}

/// Controller to synchronize the fontSize of multiple AutoSizeTexts.
class AutoSizeGroup {
  final AutoSizeGroupBehavior behavior;
  AutoSizeGroup() : behavior = AutoSizeGroupBehavior.smallest;
  AutoSizeGroup.proportional() : behavior = AutoSizeGroupBehavior.proportional;

  final _listeners = <_AutoSizeTextState, _AutoSizeGroupEntry>{};
  var _widgetsNotified = false;
  var _fontSize = double.infinity;
  var _proportion = 1.0;

  void _register(_AutoSizeTextState text) {
    _listeners[text] = _AutoSizeGroupEntry(double.infinity, double.infinity);
  }

  double get _minSize => _listeners.values.fold(double.infinity,
      (previousValue, element) => min(previousValue, element.maxFontSize));
  double get _minProportion => _listeners.values.fold(
      1, (previousValue, element) => min(previousValue, element.proportion));

  void _updateFontSize(
      _AutoSizeTextState text, double fontSize, double maxFontSize) {
    _listeners[text] = _AutoSizeGroupEntry(fontSize, maxFontSize);
    switch (behavior) {
      case AutoSizeGroupBehavior.smallest:
        final _min = _minSize;
        if (_min < _fontSize) {
          _fontSize = _min;
          _widgetsNotified = false;
          scheduleMicrotask(_notifyListeners);
        }
        break;
      case AutoSizeGroupBehavior.proportional:
        final _min = _minProportion;
        if (_min < _proportion) {
          _proportion = _min;
          _widgetsNotified = false;
          scheduleMicrotask(_notifyListeners);
        }
        break;
    }
  }

  void _notifyListeners() {
    if (_widgetsNotified) {
      return;
    } else {
      _widgetsNotified = true;
    }

    for (final textState in _listeners.keys) {
      if (textState.mounted) {
        textState._notifySync();
      }
    }
  }

  void _remove(_AutoSizeTextState text) {
    _updateFontSize(text, double.infinity, double.infinity);
    _listeners.remove(text);
  }

  double _getFontSize(double size) {
    switch (behavior) {
      case AutoSizeGroupBehavior.smallest:
        return min(size, _fontSize);
      case AutoSizeGroupBehavior.proportional:
        return size * _proportion;
    }
    return size;
  }
}
