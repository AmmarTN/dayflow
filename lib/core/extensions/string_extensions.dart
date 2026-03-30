extension StringExtension on String {
  String get firstLetterCap => this[0].toUpperCase();
  String get capitalizeEveryWord {
    if (isEmpty) return '';
    return trim()
        .split(' ')
        .map((word) => word.toCapitalized)
        .toList()
        .join(' ');
  }

  String get toCapitalized {
    if (isEmpty) return '';
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }

  String toIdentification() {
    final length = this.length;
    if (length <= 2) {
      return this;
    }

    final firstSpaceIndex = length % 2 == 0 ? 2 : 1;
    final secondSpaceIndex = firstSpaceIndex + 2;
    final thirdSpaceIndex = secondSpaceIndex + 3;

    final buffer = StringBuffer();

    for (var i = 0; i < length; i++) {
      buffer.write(this[i]);
      if (i == thirdSpaceIndex) {
        buffer.write(' ');
      }
    }

    return buffer.toString().replaceAll("  ", " ");
  }

  String toGqlResponseOperation() {
    return this[0].toLowerCase() + substring(1);
  }

  bool get isValidEmail {
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+$");
    return emailRegex.hasMatch(this);
  }
}
