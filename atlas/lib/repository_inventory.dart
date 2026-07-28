import 'package:atlas/repository_item.dart';

class RepositoryInventory {
  RepositoryInventory({
    List<RepositoryItem>? items,
  }) : items = items ?? [];

  final List<RepositoryItem> items;

  void add(RepositoryItem item) {
    items.add(item);
  }

  int get totalFiles => items.length;

  Iterable<RepositoryItem> whereCategory(String category) {
    return items.where((item) => item.category == category);
  }

  List<RepositoryItem> get pages =>
      whereCategory('page').toList();

  List<RepositoryItem> get widgets =>
      whereCategory('widget').toList();

  List<RepositoryItem> get services =>
      whereCategory('service').toList();

  List<RepositoryItem> get repositories =>
      whereCategory('repository').toList();

  List<RepositoryItem> get models =>
      whereCategory('model').toList();

  List<RepositoryItem> get tests =>
      whereCategory('test').toList();

  List<RepositoryItem> get configs =>
      whereCategory('config').toList();

  List<RepositoryItem> get scripts =>
      whereCategory('script').toList();

  List<RepositoryItem> get unknown =>
      whereCategory('unknown').toList();
}