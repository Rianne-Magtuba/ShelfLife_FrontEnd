import '../../business/dtos/product_dto.dart';

abstract class IProductDataService {
  Future<ProductResponse?> fetchProduct(String barcode);
  Future<ProductResponse> createProduct(ProductRequest request);
}