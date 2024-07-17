class Reaction {
  late final String userId;
  late final String reactionType;
  late final String timestamp;
  late final String idPostReact;

  Reaction({
    required this.userId,
    required this.reactionType,
    required this.timestamp,
    required this.idPostReact,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      userId: json['userId'],
      reactionType: json['reactionType'],
      timestamp: json['timestamp'],
      idPostReact: json['idPostReact'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userId'] = userId;
    data['reactionType'] = reactionType;
    data['timestamp'] = timestamp;
    data['idPostReact'] = idPostReact;
    return data;
  }
}
