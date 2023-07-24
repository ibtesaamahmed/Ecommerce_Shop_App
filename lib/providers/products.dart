import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_complete_guide/constants.dart';
import 'package:flutter_complete_guide/models/http_exception.dart';
import 'package:http/http.dart' as http;

import 'product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];

  final authToken;
  final userId;
  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> addProduct(Product product) async {
    final url = Uri.parse('$link/products.json?auth=$authToken');
    try {
      final response = await http.post(url,
          body: json.encode({
            'title': product.title,
            'description': product.description,
            'price': product.price,
            'imageUrl': product.imageUrl,
            'creatorId': userId,
          }));
      print(json.decode(response.body));
      final newProduct = Product(
        id: json.decode(response.body)['name'],
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
      );

      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      print(error);
      throw (error);
    }
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    var _params;
    if (filterByUser) {
      _params = <String, String>{
        'auth': authToken,
        'orderBy': json.encode('creatorId'),
        'equalTo': json.encode(userId),
      };
    }
    if (filterByUser == false)
      _params = <String, String>{
        'auth': authToken,
      };

    final url1 = Uri.https(link, '/products.json', _params);

    try {
      final response = await http.get(url1);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData.isEmpty || extractedData['error'] != null) {
        return;
      }
      final url2 =
          Uri.parse('$link/userFavorites/$userId.json?auth=$authToken');
      final favoriteResponse = await http.get(url2);
      final favoriteData = json.decode(favoriteResponse.body);

      final List<Product> loadedProducts = [];
      extractedData.forEach(((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: double.parse(prodData['price'].toString()),
          imageUrl: prodData['imageUrl'],
          isFavorite:
              favoriteData == null ? false : favoriteData[prodId] ?? false,
        ));
      }));
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere(
      (prod) => prod.id == id,
    );
    if (prodIndex >= 0) {
      final url = Uri.parse('$link/products/$id.json?auth=$authToken');
      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
            'price': newProduct.price,
          }));
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('...');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url = Uri.parse('$link/products/$id.json?auth=$authToken');
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    Product? existingProduct = _items[existingProductIndex];

    _items.removeAt(existingProductIndex);
    notifyListeners();

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not Delete Product');
    } else {
      existingProduct = null;
    }
  }
}
