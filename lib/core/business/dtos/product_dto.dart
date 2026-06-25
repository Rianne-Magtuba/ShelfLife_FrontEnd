class ProductResponse {
  final String barcode;
  final String name;
  final String category;
  final double? weightGrams;
  final double? price;

  ProductResponse({
    required this.barcode,
    required this.name,
    required this.category,
    this.weightGrams,
    this.price,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) => ProductResponse(
    barcode:     (json['barcode']     ?? json['Barcode'])  as String,
    name:        (json['name']        ?? json['Name'])      as String,
    category:    (json['category']    ?? json['Category'])  as String,
    weightGrams: ((json['weightGrams'] ?? json['WeightGrams']) as num?)?.toDouble(),
    price:       ((json['price']       ?? json['Price'])       as num?)?.toDouble(),
  );
}

class ProductRequest {
  final String barcode;
  final String name;
  final String category;
  final double? weightGrams;
  final double? price;

  ProductRequest({
    required this.barcode,
    required this.name,
    required this.category,
    this.weightGrams,
    this.price,
  });

  Map<String, dynamic> toJson() => {
    'Barcode':  barcode,
    'Name':     name,
    'Category': category,
    if (weightGrams != null) 'WeightGrams': weightGrams,
    if (price       != null) 'Price':       price,
  };
}

class ProductUpdateRequest {
  final String barcode;
  final String proposedName;
  final String proposedCategory;
  final double proposedWeightGrams;
  final double proposedPrice;

  ProductUpdateRequest({
    required this.barcode,
    required this.proposedName,
    required this.proposedCategory,
    required this.proposedWeightGrams,
    required this.proposedPrice,
  });

  Map<String, dynamic> toJson() => {
    'barcode':              barcode,
    'proposedName':         proposedName,
    'proposedCategory':     proposedCategory,
    'proposedWeightGrams':  proposedWeightGrams,
    'proposedPrice':        proposedPrice,
  };
}