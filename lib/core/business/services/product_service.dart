import '../../common/interfaces/i_product_service.dart';  // ← correct interface
import '../../data/services/ product_data_service.dart';
import '../dtos/product_dto.dart';

class ProductService implements IProductDataService {
  final _data = ProductDataService();

  @override
  Future<ProductResponse?> fetchProduct(String barcode) =>  // ← was getProduct
  _data.fetchProduct(barcode);

  @override
  Future<ProductResponse> createProduct(ProductRequest request) =>  // ← was registerProduct
  _data.createProduct(request);
}