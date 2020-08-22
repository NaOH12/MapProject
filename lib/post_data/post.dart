import 'package:intl/intl.dart';
import 'package:latlong/latlong.dart';

abstract class BasePost {
  Map<String, dynamic> toJson();
}

class Post extends BasePost {
  final int postId;
  final String postContent;
  final LatLng point;
  final int tileId;

  Post(this.postId, this.postContent, this.point, this.tileId);

  factory Post.fromJson(Map<String, dynamic> json) => new Post(
        json['id'],
        json['post_content'],
        LatLng(json['latitude'], json['longitude']),
        json['tile_id'],
      );

  factory Post.fromJsonWithTileId(Map<String, dynamic> json, int tileId) =>
      new Post(
        json['id'],
        json['post_content'],
        LatLng(json['latitude'], json['longitude']),
        tileId,
      );

  Map<String, dynamic> toJson() => {
        "id": postId,
        "post_content": postContent,
        "latitude": point.latitude,
        "longitude": point.longitude,
        "tile_id": tileId,
      };

  String toString() {
    return "[$postId], $postContent, (Lat ${point.latitude}, Lon ${point.longitude}), tile_id: $tileId";
  }
}

class ArtPost extends BasePost {
  final int postId;
  final LatLng point;
  final int tileId;

  ArtPost(this.postId, this.point, this.tileId);

  @override
  factory ArtPost.fromJson(Map<String, dynamic> json) => new ArtPost(
        json['id'],
        LatLng(json['latitude'], json['longitude']),
        json['tile_id'],
      );

  @override
  factory ArtPost.fromJsonWithTileId(Map<String, dynamic> json, int tileId) =>
      new ArtPost(
        json['id'],
        LatLng(json['latitude'], json['longitude']),
        tileId,
      );

  Map<String, dynamic> toJson() => {
        "id": postId,
        "latitude": point.latitude,
        "longitude": point.longitude,
      };
}
