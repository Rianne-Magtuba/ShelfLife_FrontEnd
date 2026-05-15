import 'dart:convert';
import '../models/auth_models.dart';
import 'api_client.dart';

abstract class IProductService {
  Future<ProductResponse?> getProduct(String barcode);
  Future<ProductResponse> registerProduct(ProductRequest request);
}

// ── MOCK ──────────────────────────────────────────────────────────────────────

class MockProductService implements IProductService {
  // A small fake catalog — simulates what's in Firestore's "Product Catalog"
  static final _catalog = <String, ProductResponse>{
    '4800016505016': ProductResponse(
      barcode:     '4800016505016',
      name:        'Bear Brand Milk',
      category:    'Pantry',
      weightGrams: 33,
      price:       12.50,
    ),
    '4800888832001': ProductResponse(
      barcode:     '4800888832001',
      name:        'Nestle All Purpose Cream',
      category:    'Fridge',
      weightGrams: 250,
      price:       65.00,
    ),
  };

  @override
  Future<ProductResponse?> getProduct(String barcode) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Returns null for unknown barcodes → triggers RegisterProduct flow
    return _catalog[barcode];
  }

  @override
  Future<ProductResponse> registerProduct(ProductRequest request) async {
    await Future.delayed(const Duration(seconds: 1));
    final product = ProductResponse(
      barcode:     request.barcode,
      name:        request.name,
      category:    request.category,
      weightGrams: request.weightGrams,
      price:       request.price,
    );
    _catalog[request.barcode] = product; // save locally for this session
    return product;
  }
}

// ── REAL ──────────────────────────────────────────────────────────────────────

class ProductService implements IProductService {
  @override
  Future<ProductResponse?> getProduct(String barcode) async {
    final response = await ApiClient.get('/api/products/$barcode');

    if (response.statusCode == 200) {
      return ProductResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      return null; // product not in catalog → show RegisterProduct screen
    } else {
      throw Exception(
          ApiClient.parseError(response, 'Failed to look up product.'));
    }
  }

  @override
  Future<ProductResponse> registerProduct(ProductRequest request) async {
    final response = await ApiClient.post(
      '/api/products',
      request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ProductResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception(
          ApiClient.parseError(response, 'Failed to register product.'));
    }
  }
}