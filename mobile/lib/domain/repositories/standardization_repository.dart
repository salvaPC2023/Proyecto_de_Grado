class StandardizationException implements Exception {
  const StandardizationException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class StandardizationRepository {
  Future<String> standardize(String text);
}
