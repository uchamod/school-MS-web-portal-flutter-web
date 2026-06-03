import 'package:equatable/equatable.dart';

class SchoolImage extends Equatable {
  final String? id;
  final String imageUrl;

  const SchoolImage({
    this.id,
    required this.imageUrl,
  });

  factory SchoolImage.fromJson(Map<String, dynamic> json) {
    return SchoolImage(
      id: json['id'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['imagePath'] as String? ?? json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'imageUrl': imageUrl,
    };
  }

  @override
  List<Object?> get props => [id, imageUrl];
}
