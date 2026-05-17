import 'dart:convert';
import '../../common/interfaces/i_product_service.dart';
import '../../business/dtos/product_dto.dart';
import 'api_client.dart';

class ProductDataService implements IProductDataService {

  @override
  Future<ProductResponse?> fetchProduct(String barcode) async {
    final response = await ApiClient.get('/api/Product/$barcode');

    if (response.statusCode == 200) {
      return ProductResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 404) {
      return null;
    }

    throw Exception(ApiClient.parseError(response, 'Failed to look up product.'));
  }

  @override
  Future<ProductResponse> createProduct(ProductRequest request) async {
    final response = await ApiClient.post('/api/Product', request.toJson());

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ProductResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(ApiClient.parseError(response, 'Failed to register product.'));
  }
}