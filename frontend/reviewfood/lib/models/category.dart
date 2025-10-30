class Category {
  final int id;
  final String name;
  final String? image;

  Category({required this.id, required this.name, this.image});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
    );
  }
}
