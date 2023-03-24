extension StringExtension on String {
  bool hasPrefix(String prefix) {
    return substring(0, prefix.length) == prefix;
  }

  bool hasSuffix(String suffix) {
    return substring(length - suffix.length) == suffix;
  }
}
