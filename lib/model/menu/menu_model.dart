class MenuPdfModel {
  final String uuid;
  final String pdfPath;
  final String menuName;
  final String status;

  MenuPdfModel({
    required this.uuid,
    required this.pdfPath,
    required this.menuName,
    required this.status,
  });

  factory MenuPdfModel.fromJson(Map<String, dynamic> json) {
    return MenuPdfModel(
      uuid: json['uuid']?.toString() ?? '',
      pdfPath: json['pdf_path']?.toString() ?? '',
      menuName: json['menu_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class MenuItemModel {
  final String uuid;
  final String itemName;
  final String itemPrice;
  final String itemDescription;
  final String? itemImage;
  final String itemCategory;
  final String status;

  MenuItemModel({
    required this.uuid,
    required this.itemName,
    required this.itemPrice,
    required this.itemDescription,
    this.itemImage,
    required this.itemCategory,
    required this.status,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      uuid: json['uuid']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? '',
      itemPrice: json['item_price']?.toString() ?? '',
      itemDescription: json['item_description']?.toString() ?? '',
      itemImage: json['item_image']?.toString(),
      itemCategory: json['item_category']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class MenuResponse {
  final bool status;
  final List<MenuPdfModel> pdfs;
  final List<MenuItemModel> individualMenu;

  MenuResponse({
    required this.status,
    required this.pdfs,
    required this.individualMenu,
  });

  factory MenuResponse.fromJson(Map<String, dynamic> json) {
    return MenuResponse(
      status: json['status'] == true,
      pdfs: (json['pdf'] as List? ?? [])
          .map((e) => MenuPdfModel.fromJson(e))
          .toList(),
      individualMenu: (json['individual_menu'] as List? ?? [])
          .map((e) => MenuItemModel.fromJson(e))
          .toList(),
    );
  }
}