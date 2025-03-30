class Capitalize {
  String capitalize(String input) {
    if (input.isEmpty) return input;

    return input
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
