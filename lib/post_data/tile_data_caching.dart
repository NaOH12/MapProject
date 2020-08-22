import 'dart:io';

import 'package:flutterapp/post_data/post.dart';
import 'package:flutterapp/post_data/tile.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:math' as math;

class DBProvider {
  DBProvider._internal();
  static final DBProvider _db = DBProvider._internal();

  factory DBProvider() {
    return _db;
  }

  Database _database;
  final maxPostsPerTile = 10;

  Future<Database> get database async {
    if (_database != null) return _database;

    // if _database is null we instantiate it
    _database = await initDB();
    return _database;
  }

  Future<Database> initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "database.db");
    deleteDatabase(path);
    return await openDatabase(path, version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) async {
      await db.execute("CREATE TABLE Tile ("
          "id INTEGER PRIMARY KEY,"
          "x TEXT,"
          "y TEXT"
          ")");
      await db.execute("CREATE TABLE Post ("
          "id INTEGER PRIMARY KEY,"
          "post_content TEXT,"
          "longitude FLOAT,"
          "latitude FLOAT,"
          "tile_id INT REFERENCES Tile(id) ON UPDATE CASCADE"
          ")");
    });
  }

  Future<int> newPost(Post post, Tile tile) async {
    // Posts need a tile parent
    if (getTile(tile.id) == null) {
      newTile(tile);
    }
    final db = await database;
    var res = await db.insert("Post", post.toJson());
    return res;
  }

  Future<void> newPosts(List<Post> posts, Tile tile) async {
    // Posts need a tile parent
    if (getTile(tile.id) == null) {
      newTile(tile);
    }
    final db = await database;
    var batch = db.batch();
    for (final post in posts) {
      batch.insert("Post", post.toJson());
    }
    batch.commit();
    // Limit the number of posts per tile
    _pruneTilePosts(maxPostsPerTile, tile.id);
  }

  Future<void> _pruneTilePosts(int max, int tileId) async {
    //delete from TheTable where rowid in (SELECT rowid FROM TheTable limit 1);
    final db = await database;
    var res = await db
        .rawQuery("SELECT COUNT(*) as size FROM Post WHERE tile_id = $tileId");
    int size = res.first['size']; //int.parse(res.first['size']);
    var toRemove = math.max(size - max, 0);
    await db.rawDelete(
        "DELETE FROM Post WHERE id in (SELECT id FROM Post WHERE tile_id=$tileId ORDER BY id ASC LIMIT $toRemove)");
  }

  Future<Post> getPost(int id) async {
    final db = await database;
    var res = await db.query("Post", where: "id = ?", whereArgs: [id]);
    return res.isNotEmpty ? Post.fromJson(res.first) : Null;
  }

  Future<int> updatePost(Post newPost) async {
    final db = await database;
    var res = await db.update("Post", newPost.toJson(),
        where: "id = ?", whereArgs: [newPost.postId]);
    return res;
  }

  void deletePost(int id) async {
    final db = await database;
    db.delete("Post", where: "id = ?", whereArgs: [id]);
  }

  void deleteAllPost() async {
    final db = await database;
    db.rawDelete("Delete * from Post");
  }

  Future<int> newTile(Tile tile) async {
    final db = await database;
    var res = await db.insert("Tile", tile.toJson());
    return res;
  }

  Future<Tile> getTile(int id) async {
    final db = await database;
    var res = await db.query("Tile", where: "id = ?", whereArgs: [id]);
    return res.isNotEmpty ? Tile.fromJson(res.first) : null;
  }

  Future<List<Post>> getPostsByTile(int tileId) async {
    final db = await database;
    var res = await db.rawQuery("SELECT * FROM Post WHERE tile_id=$tileId");
    List<Post> list =
        res.isNotEmpty ? res.map((c) => Post.fromJson(c)).toList() : null;
//        res.isNotEmpty ? res.toList().map((c) => Post.fromJson(c)) : null;
    return list;
  }

  Future<Post> getLatestPostByTile(int tileId) async {
    final db = await database;
    var res = await db.rawQuery(
        "SELECT * FROM Post WHERE tile_id=$tileId ORDER BY id DESC LIMIT 1");
    return res.isNotEmpty ? Tile.fromJson(res.first) : Null;
  }

//  updateTile(Tile newTile) async {
//    final db = await database;
//    var res = await db.update("Tile", newTile.toMap(),
//        where: "id = ?", whereArgs: [newTile.id]);
//    return res;
//  }

  Future<void> deleteTile(int id) async {
    final db = await database;
    db.delete("Tile", where: "id = ?", whereArgs: [id]);
  }

  Future<void> deleteAllTile() async {
    final db = await database;
    db.rawDelete("Delete * from Tile");
  }
}
