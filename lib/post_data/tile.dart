import 'package:flutter_map/flutter_map.dart';

class Tile {
  final int id;
  Coords point;

  Tile(this.id, this.point);

  factory Tile.fromJson(Map<String, dynamic> json) => new Tile(
    json['id'],
    Coords(json['x'],
    json['y'])
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "x": point.x,
    "y": point.y,
  };
}