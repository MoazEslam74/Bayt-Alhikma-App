class Book {
  final String? id;
  final String? nameAR;
  final String? nameEN;
  final String? authorAR;
  final String? authorEN;
  final String? descriptionAR;
  final String? descriptionEN;
  final String? image;
  final String? audio;
  final String? pdf;
  final int? price;
  final bool? isSaved;

  Book({
    required this.id,
    required this.nameAR,
    required this.nameEN,
    required this.authorAR,
    required this.authorEN,
    required this.descriptionAR,
    required this.descriptionEN,
    this.image,
    this.audio,
    this.pdf,
    this.price,
    this.isSaved = false,
  });
}
