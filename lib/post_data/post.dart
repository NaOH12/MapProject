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
  LatLng point;
  double rotation;
  final int tileId;

  ArtPost(this.postId, this.point, this.tileId, this.rotation);

//  factory ArtPost.fromJson(Map<String, dynamic> json) => new ArtPost(
//        json['id'],
//        LatLng(json['latitude'], json['longitude']),
//        json['tile_id'],
//        json['rotation'],
//      );

//  factory ArtPost.fromJsonWithTileId(Map<String, dynamic> json, int tileId) =>
//      new ArtPost(
//        json['id'],
//        LatLng(json['latitude'], json['longitude']),
//        tileId,
//        json['rotation'],
//      );

  Map<String, dynamic> toJson() => {
        "id": postId,
        "latitude": point.latitude,
        "longitude": point.longitude,
        "rotation": rotation,
      };
}

class TextArtPost extends ArtPost {
  String textContent;
  int colour;
  int font;
  double size;

  TextArtPost(int postId, LatLng point, int tileId, double rotation,
      this.textContent, this.colour, this.font, this.size)
      : super(postId, point, tileId, rotation);

  @override
  factory TextArtPost.fromJson(Map<String, dynamic> json) => new TextArtPost(
    json['id'],
    LatLng(json['latitude'], json['longitude']),
    json['tile_id'],
    json['rotation'],
    json['postable']['text_content'],
    json['postable']['colour'],
    json['postable']['font'],
    json['postable']['size'],
  );

  @override
  factory TextArtPost.fromJsonWithTileId(Map<String, dynamic> json, int tileId) =>
      new TextArtPost(
        json['id'],
        LatLng(json['latitude'], json['longitude']),
        tileId,
        json['rotation'],
        json['postable']['text_content'],
        json['postable']['colour'],
        json['postable']['font'],
        json['postable']['size'],
      );

  @override
  Map<String, dynamic> toJson() => {
    "id": postId,
    "latitude": point.latitude,
    "longitude": point.longitude,
    "rotation": rotation,
    "text_content": textContent,
    "colour": colour,
    "font": font,
    "size": size,
  };

}
