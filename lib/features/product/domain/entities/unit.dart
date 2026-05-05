enum Unit {
  g('g', 'G'),
  kg('kg', 'KG'),
  ml('ml', 'ML'),
  l('l', 'L');

  final String displayName;
  final String serverValue;

  const Unit(this.displayName, this.serverValue);

  static Unit? fromString(String? value) {
    if (value == null) return null;
    final lowerValue = value.toLowerCase();
    try {
      return Unit.values.firstWhere(
        (e) => e.displayName == lowerValue || e.serverValue == value.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
