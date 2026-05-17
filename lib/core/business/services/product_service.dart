import 'dart:convert';
import '../../common/interfaces/i_product_service.dart';
import '../dtos/product_dto.dart';
import '../../data/services/api_client.dart';

class ProductService implements IProductService {
  @override
  Future<ProductResponse?> getProduct(String barcode) async {
    final response = await ApiClient.get('/api/Product/$barcode');

    if (response.statusCode == 200) {
      return ProductResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception(ApiClient.parseError(response, 'Failed to look up product.'));
    }
  }

  @override
  Future<ProductResponse> registerProduct(ProductRequest request) async {
    final response = await ApiClient.post('/api/Product', request.toJson());

    if (response. statusCode == 200 || response.statusCode == 201) {
      return ProductResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception(ApiClient.parseError(response, 'Failed to register product.'));
    }
  }
}