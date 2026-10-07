/// One page of a list endpoint: `{ items, page, size, totalItems }`.
class PageResult<T> {
  const PageResult({required this.items, required this.page, required this.size, required this.totalItems});

  factory PageResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromItem) => PageResult(
    items: (json['items'] as List<dynamic>).map((e) => fromItem(e as Map<String, dynamic>)).toList(),
    page: json['page'] as int,
    size: json['size'] as int,
    totalItems: json['totalItems'] as int,
  );

  final List<T> items;
  final int page;
  final int size;
  final int totalItems;

  bool get hasMore => (page + 1) * size < totalItems;
}
