class QRItem {
  final String name;
  final String url;

  QRItem({required this.name, required this.url});

  String toStorageString() => '$name • $url';

  static QRItem fromStorageString(String value) {
    final parts = value.split(' • ');
    return QRItem(
      name: parts.first,
      url: parts.length > 1 ? parts.last : '',
    );
  }
}