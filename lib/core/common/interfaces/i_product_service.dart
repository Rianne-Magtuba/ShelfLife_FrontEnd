import '../../business/dtos/product_dto.dart'; // ← single source

abstract class IProductService {
  Future<ProductResponse?> getProduct(String barcode);
  Future<ProductResponse> registerProduct(ProductRequest request);
}