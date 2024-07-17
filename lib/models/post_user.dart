class PostUser {
  PostUser({
    required this.caption,
    required this.imageUrl,
    required this.timestamp,
    required this.userId,
    required this.type,
    required this.visibleTo,
    required this.idpost,
  });

  late final String caption;
  late final String imageUrl;
  late final String timestamp;
  late final String userId;
  late final PostType type;
  late final List<String> visibleTo;
  late final String idpost;

  PostUser.fromJson(Map<String, dynamic> json) {
    caption = json['caption'].toString();
    imageUrl = json['imageUrl'].toString();
    timestamp = json['timestamp'].toString();
    userId = json['userId'].toString();
    type = json['type'].toString() == PostType.image.name ? PostType.image : PostType.text;
    visibleTo = List<String>.from(json['visibleTo']);
    idpost = json['idpost'].toString();

  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['caption'] = caption;
    data['imageUrl'] = imageUrl;
    data['timestamp'] = timestamp;
    data['userId'] = userId;
    data['type'] = type.name;
    data['visibleTo'] = visibleTo;
    data['idpost'] = idpost;

    return data;
  }
}

enum PostType { text, image }
