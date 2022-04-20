import 'dart:convert';

class IPTV {
  final String name;
  final String url;

  IPTV({
    required this.name,
    required this.url,
  });

  // Convert a Breed into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url':url,
    };
  }

  factory IPTV.fromMap(Map<String, dynamic> map) {
    return IPTV(
      name: map['name'] ?? '',
      url: map['url'] ?? '',
    );
  }

  // Implement toString to make it easier to see information about
  // each breed when using the print statement.
  @override
  String toString() => 'IPTV(name: $name,url: $url)';
}