import 'package:idlefit/models/shop_items.dart';
import 'package:objectbox/objectbox.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class ShopItemsRepo {
  final Box<ShopItem> box;
  ShopItemsRepo({required this.box});

  Future<List<ShopItem>> parseShopItems(String jsonString) async {
    final String response = await rootBundle.loadString(jsonString);
    final List<dynamic> data = jsonDecode(response);

    return data.map((d) {
      ShopItem item = ShopItem.fromJson(d);
      final stored = box.get(item.id);
      if (stored == null) {
        return item;
      }
      item.level = stored.level;
      return item;
    }).toList();
  }
}