class PostUser {
  PostUser({
    required this.caption,
    required this.imageUrl,
    required this.timestamp,
    required this.userId,
    required this.type,

  });

  late final String caption;
  late final String imageUrl;
  late final String timestamp;
  late final String userId;
  late final Type type;


  PostUser.fromJson(Map<String, dynamic> json) {
    caption = json['caption'].toString();
    imageUrl = json['imageUrl'].toString();
    userId = json['userId'].toString();
    type = json['type'].toString() == Type.image.name ? Type.image : Type.text;

    timestamp = json['timestamp'].FieldValue.serverTimestamp().toString();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['caption'] = caption;
    data['imageUrl'] = imageUrl;
    data['timestamp'] = timestamp;
    data['userId'] = userId;
    data['type'] = type.name;

    return data;
  }
}

enum Type { text, image }
