import 'dart:io';

import 'package:flutter/cupertino.dart';
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
  final maxArtPostsPerTile = 10;

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
      await db.execute("CREATE TABLE ArtTile ("
          "id INTEGER PRIMARY KEY,"
          "x TEXT,"
          "y TEXT"
          ")");
      await db.execute("CREATE TABLE TextArtPost ("
          "id INTEGER PRIMARY KEY,"
          "longitude FLOAT,"
          "latitude FLOAT,"
          "rotation FLOAT,"
          "text_content TEXT,"
          "colour INT,"
          "font INT,"
          "size FLOAT,"
          "tile_id INT REFERENCES Tile(id) ON UPDATE CASCADE"
          ")");
    });
  }

  // This function finds the table name for the corresponding art post
  // child. This is a solution for the art posts database
  // inheritance relationship.
  String getArtTableName(ArtPost post) {
    if (post is TextArtPost) {
      return "TextArtPost";
    } else {
      return null;
    }
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

  Future<int> newArtPost(ArtPost post, Tile tile) async {
    // Posts need a tile parent
    if (getArtTile(tile.id) == null) {
      newArtTile(tile);
    }
    final db = await database;
    var res = await db.insert(getArtTableName(post), post.toJson());
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

  //warning this only currently works with textartpost
  Future<void> newArtPosts(List<ArtPost> posts, Tile tile) async {
    // Posts need a tile parent
    if (getArtTile(tile.id) == null) {
      newArtTile(tile);
    }
    final db = await database;
    var batch = db.batch();
    for (final post in posts) {
      batch.insert(getArtTableName(post), post.toJson());
    }
    batch.commit();
    // Limit the number of posts per tile
    _pruneArtTilePosts(maxArtPostsPerTile, tile.id);
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

  //warning this only currently works with textartpost
  Future<void> _pruneArtTilePosts(int max, int tileId) async {
    //delete from TheTable where rowid in (SELECT rowid FROM TheTable limit 1);
    final db = await database;
    var res = await db
        .rawQuery("SELECT COUNT(*) as size FROM TextArtPost WHERE tile_id = $tileId");
    int size = res.first['size']; //int.parse(res.first['size']);
    var toRemove = math.max(size - max, 0);
    await db.rawDelete(
        "DELETE FROM TextArtPost WHERE id in (SELECT id FROM TextArtPost WHERE tile_id=$tileId ORDER BY id ASC LIMIT $toRemove)");
  }

  Future<Post> getPost(int id) async {
    final db = await database;
    var res = await db.query("Post", where: "id = ?", whereArgs: [id]);
    return res.isNotEmpty ? Post.fromJson(res.first) : Null;
  }

  //warning this only currently works with textartpost
  Future<ArtPost> getTextArtPost(int id) async {
    final db = await database;
    var res = await db.query("TextArtPost", where: "id = ?", whereArgs: [id]);
    return res.isNotEmpty ? TextArtPost.fromJson(res.first) : Null;
  }

  Future<int> updatePost(Post newPost) async {
    final db = await database;
    var res = await db.update("Post", newPost.toJson(),
        where: "id = ?", whereArgs: [newPost.postId]);
    return res;
  }

  Future<int> updateArtPost(ArtPost newPost) async {
    final db = await database;
    var res = await db.update(getArtTableName(newPost), newPost.toJson(),
        where: "id = ?", whereArgs: [newPost.postId]);
    return res;
  }

  void deletePost(int id) async {
    final db = await database;
    db.delete("Post", where: "id = ?", whereArgs: [id]);
  }

  void deleteTextArtPost(int id) async {
    final db = await database;
    db.delete("TextArtPost", where: "id = ?", whereArgs: [id]);
  }

  void deleteAllPosts() async {
    final db = await database;
    db.rawDelete("Delete * from Post");
  }

  void deleteAllArtPosts() async {
    final db = await database;
    db.rawDelete("Delete * from TextArtPost");
  }

  Future<int> newTile(Tile tile) async {
    final db = await database;
    var res = await db.insert("Tile", tile.toJson());
    return res;
  }

  Future<int> newArtTile(Tile tile) async {
    final db = await database;
    var res = await db.insert("ArtTile", tile.toJson());
    return res;
  }

  Future<Tile> getTile(int id) async {
    final db = await database;
    var res = await db.query("Tile", where: "id = ?", whereArgs: [id]);
    return res.isNotEmpty ? Tile.fromJson(res.first) : null;
  }

  Future<Tile> getArtTile(int id) async {
    final db = await database;
    var res = await db.query("ArtTile", where: "id = ?", whereArgs: [id]);
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

  Future<List<ArtPost>> getTextArtPostsByTile(int tileId) async {
    final db = await database;
    var res = await db.rawQuery("SELECT * FROM TextArtPost WHERE tile_id=$tileId");
    List<ArtPost> list =
    res.isNotEmpty ? res.map((c) => TextArtPost.fromJson(c)).toList() : null;
//        res.isNotEmpty ? res.toList().map((c) => Post.fromJson(c)) : null;
    return list;
  }

  Future<List<ArtPost>> getArtPostsByTile(int tileId) async {
    return await getTextArtPostsByTile(tileId);
  }

  Future<Post> getLatestPostByTile(int tileId) async {
    final db = await database;
    var res = await db.rawQuery(
        "SELECT * FROM Post WHERE tile_id=$tileId ORDER BY id DESC LIMIT 1");
    return res.isNotEmpty ? Tile.fromJson(res.first) : Null;
  }

  Future<ArtPost> getLatestTextArtPostByTile(int tileId) async {
    final db = await database;
    var res = await db.rawQuery(
        "SELECT * FROM TextArtPost WHERE tile_id=$tileId ORDER BY id DESC LIMIT 1");
    return res.isNotEmpty ? Tile.fromJson(res.first) : Null;
  }

  Future<ArtPost> getLatestArtPostByTile(int tileId) async {
    return await getLatestTextArtPostByTile(tileId);
  }

  Future<void> deleteTile(int id) async {
    final db = await database;
    db.delete("Tile", where: "id = ?", whereArgs: [id]);
  }

  Future<void> deleteAllTile() async {
    final db = await database;
    db.rawDelete("Delete * from Tile");
  }

  Future<void> deleteArtTile(int id) async {
    final db = await database;
    db.delete("ArtTile", where: "id = ?", whereArgs: [id]);
  }

  Future<void> deleteAllArtTile() async {
    final db = await database;
    db.rawDelete("Delete * from ArtTile");
  }

}
