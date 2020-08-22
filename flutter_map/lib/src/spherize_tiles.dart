import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer.dart';

class Spherize {
  int xCenter;
  int yCenter;
  int width;
  int height;
  Uint32List mappingX;
  Uint32List mappingY;
  Float32List mappingR;
//  Float32List invertCircleVertices;
  Vertices circleVerts;
//  Int32List circleRgbaList;
  bool isMappedBuilt = false;
  double scaleFactor;

  static final Spherize _singleton = Spherize._internal();

  factory Spherize(int width, int height, double scale) {
    if (_singleton.isMappedBuilt == false) {
      _singleton._buildMapping(width, height, scale);
      _singleton._buildCircleMapping(width, height, 2);
      _singleton.isMappedBuilt = true;
      _singleton.scaleFactor = scale;
    }
    return _singleton;
  }

  Spherize._internal();

  double norm(int val, int size) {
    return ((val / size) - 0.5) * 2.0;
  }

  int denorm(double val, int size) {
    return (((val / 2.0) + 0.5) * size).toInt();
  }

  int denormDown(double val, int size) {
    return (((val / 2.0) + 0.5) * size).floor();
  }

  int denormUp(double val, int size) {
    return (((val / 2.0) + 0.5) * size).ceil();
  }

  Offset getSpherePointFromPoint(Offset point, double effectVal) {
    int x = point.dx.toInt();
    int y = point.dy.toInt();
    int mapping = y * width + x;
    return Offset(
        (((mappingX[mapping] - x) * effectVal) + x).toDouble(),
        (((mappingY[mapping] - y) * effectVal) + y).toDouble());
  }

  CustomPoint getPoint(
      int x, int y, int offsetX, int offsetY, double effectVal) {
    int mapping = y * width + x;
    return CustomPoint(
        (((mappingX[mapping] - x) * effectVal) + x + offsetX).toDouble(),
        (((mappingY[mapping] - y) * effectVal) + y + offsetY).toDouble());
  }

  void _buildCircleMapping(int width, int height, double increment) {
    final double halfWidth = width / 2;
    final double halfHeight = height / 2;
    final double degreeConversion = pi / 180;
    final int pointCount = (360 ~/ increment) * 12;
    Float32List invertCircleVertices = Float32List(pointCount);
    Int32List circleRgbaList = Int32List(pointCount ~/ 2);

    double prevCX = halfWidth;
    double prevCY = 0;
    double prevOX = halfWidth;
    double prevOY = 0;

    int index = 0;
    int rgbaIndex = 0;
    for (double degree = increment; degree < 360; degree += increment) {
      double radian = degree * degreeConversion;
      double x = sin(radian);
      double y = -cos(radian);
      double radius = sqrt(pow(x * halfWidth, 2) + pow(y * halfHeight, 2));
      double cX = (x * radius) + halfWidth;
      double cY = (y * radius) + halfHeight;

      //calculate the vertex at the edge of the screen
      double outerX = (1 - x * halfWidth);
      double outerY = (1 - y * halfHeight);

      // Old Outer Vertex (triangle 1)
      invertCircleVertices[index + 0] = prevOX;
      invertCircleVertices[index + 1] = prevOY;
      // Old Circle Vertex (triangle 1)
      invertCircleVertices[index + 2] = prevCX;
      invertCircleVertices[index + 3] = prevCY;
      // New Circle Vertex (triangle 1)
      invertCircleVertices[index + 4] = cX;
      invertCircleVertices[index + 5] = cY;
      // New Circle Vertex (triangle 2)
      invertCircleVertices[index + 6] = cX;
      invertCircleVertices[index + 7] = cX;
      // New Outer Vertex (triangle 2)
      invertCircleVertices[index + 8] = outerX;
      invertCircleVertices[index + 9] = outerY;
      // Old Outer Vertex (triangle 2)
      invertCircleVertices[index + 10] = prevOX;
      invertCircleVertices[index + 11] = prevOX;

      circleRgbaList[rgbaIndex + 0] = Color.fromARGB(255, 20, 20, 100).value;
      circleRgbaList[rgbaIndex + 1] = Color.fromARGB(255, 60, 20, 100).value;
      circleRgbaList[rgbaIndex + 2] = Color.fromARGB(255, 60, 20, 100).value;
      circleRgbaList[rgbaIndex + 3] = Color.fromARGB(255, 60, 20, 100).value;
      circleRgbaList[rgbaIndex + 4] = Color.fromARGB(255, 20, 20, 100).value;
      circleRgbaList[rgbaIndex + 5] = Color.fromARGB(255, 20, 20, 100).value;

      prevCX = x;
      prevCY = y;
      prevOX = outerX;
      prevOY = outerY;
      index += 12;
      rgbaIndex += 6;
    }

    circleVerts = Vertices.raw(VertexMode.triangles, invertCircleVertices,
        colors: circleRgbaList);
  }

  void _buildMapping(int width, int height, double scale) {
    this.width = width;
    this.height = height;
    xCenter = width ~/ 2;
    yCenter = height ~/ 2;

    final int scaledHeight = (height * scale).toInt();
    final int topScaledOffset = (height - (height * scale)) ~/ 2;
    final int bottomScaledOffset = height - topScaledOffset;

    mappingX = Uint32List(width * height);
    mappingY = Uint32List(width * height);
    mappingR = Float32List(width * height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        int index = y * width + x;
        mappingX[index] = 0;
        mappingY[index] = 0;
        mappingR[index] = 1.0;
      }
    }

    for (var y2 = 0; y2 < height; y2++) {
      bool spherized = false;
      if (y2 >= topScaledOffset && y2 < bottomScaledOffset) {
        spherized = true;
        print(height);
        print(scaledHeight);
        print(topScaledOffset);
        print(bottomScaledOffset);
        print("\n\n");
      }

      if (!spherized) {
        for (var x2 = 0; x2 < width; x2++) {
          int index = y2 * width + x2;
          mappingX[index] = x2;
          mappingY[index] = y2;
        }
      } else {
        for (var x2 = 0; x2 < width; x2++) {
          // Find vector relative to center
          int dX = x2 - xCenter;
          int dY = y2 - yCenter;

          // Normalise point
          double normX1 = norm(x2, width);
          double normY1 = norm(y2 - topScaledOffset, scaledHeight);
          // Get radius distance
          double r2 = sqrt(pow(normX1, 2) + pow(normY1, 2));
          // New coordinates un-norm
          int x1D = x2;
          int y1D = y2;
          int x1U = x2;
          int y1U = y2;

          // If within circle then calc new mapping
          if (r2 <= 1) {
            double theta = atan2(normY1, normX1);
            double r1 = asin(r2) / (pi / 2);
            normX1 = r1 * cos(theta);
            normY1 = r1 * sin(theta);
            x1D = denormDown(normX1, width);
            y1D = denormDown(normY1, scaledHeight) + topScaledOffset;
            x1U = denormUp(normX1, width);
            y1U = denormUp(normY1, scaledHeight) + topScaledOffset;
          }

//        int index = y2 * width + x2;
//        mappingX[index] = x1;
//        mappingY[index] = y1;
//        mappingR[index] = r2;
          int index = y1D * width + x1D;
          mappingX[index] = x2;
          mappingY[index] = y2;
          index = y1U * width + x1U;
          mappingX[index] = x2;
          mappingY[index] = y2;
//        mappingR[index] =
        }
      }
    }

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        int index = y * width + x;
        if (mappingX[index] == 0) {
          int validNeighbours = 0;
          int average = 0;
          if (x > 0 && mappingX[index - 1] != 0) {
            average += mappingX[index - 1];
            validNeighbours++;
          }
          if (x < width - 1 && mappingX[index + 1] != 0) {
            average += mappingX[index + 1];
            validNeighbours++;
          }
          if (y > 0 && mappingX[index - width] != 0) {
            average += mappingX[index - width];
            validNeighbours++;
          }
          if (y < height - 1 && mappingX[index + width] != 0) {
            average += mappingX[index + width];
            validNeighbours++;
          }
          if (validNeighbours > 0) {
            mappingX[index] = average ~/ validNeighbours;
          } else {
            mappingX[index] = x;
          }
        }

        if (mappingY[index] == 0) {
          int validNeighbours = 0;
          int average = 0;
          if (x > 0 && mappingY[index - 1] != 0) {
            average += mappingY[index - 1];
            validNeighbours++;
          }
          if (x < width - 1 && mappingY[index + 1] != 0) {
            average += mappingY[index + 1];
            validNeighbours++;
          }
          if (y > 0 && mappingY[index - width] != 0) {
            average += mappingY[index - width];
            validNeighbours++;
          }
          if (y < height - 1 && mappingY[index + width] != 0) {
            average += mappingY[index + width];
            validNeighbours++;
          }
          if (validNeighbours > 0) {
            mappingY[index] = average ~/ validNeighbours;
          } else {
            mappingY[index] = y;
          }
        }
      }
    }
  }
}

Future<ui.Image> loadImage(String fileName) async {
  Uint8List lst = new Uint8List.view(
      (await rootBundle.load("assets/images/" + fileName)).buffer);
  var image =
      (await (await ui.instantiateImageCodec(lst)).getNextFrame()).image;
  return image;
}

Future<Map<String, ui.Image>> loadAssetImages() async {
  Map<String, ui.Image> map = Map();
  map["earth_overlay"] = await loadImage("earth_overlay.png");
  return map;
}

class MapPainter extends CustomPainter {
  Size scaledSize;
  List<Tile> tiles;
  Size tileSize;
  Spherize spherize;
  ui.Image sphereOverlay;
  double spherizeEffect;

  MapPainter(this.scaledSize, this.tiles, this.tileSize, this.spherize,
      this.sphereOverlay, this.spherizeEffect);

  _drawTileMesh(
      Canvas canvas,
      Tile tile,
      int left,
      int top,
      int tileWidth,
      int tileHeight,
      int width,
      int height,
      int textWidth,
      int textHeight,
      int increment,
      Spherize spherize,
      int offsetX,
      int offsetY) {
    // 6 points for 2 triangles (rect). 2 floats per point.
    final int faceVertexCount = 12;

    // Theres no point renedering mesh which is out of screen
    // It also cannot be mapped by spherize
    int clipLeft = max(0, left);
    int clipTop = max(0, top);
    int clipTileWidth = tileWidth;
    int clipTileHeight = tileHeight;

    // Here if left/top are negative then we
    // adjust the visible width/height
    if (left < 0) clipTileWidth += left;
    if (top < 0) clipTileHeight += top;

    if (clipTileWidth + clipLeft > width) {
      clipTileWidth = width - clipLeft;
    }

    if (clipTileHeight + clipTop > height) {
      clipTileHeight = height - clipTop;
    }

    // Keep track of the clip offset
    // Useful for texture mapping
    final xOffset = (0 - left);
    final yOffset = (0 - top);

    // Tile width/height is scaled whereas the tile image is a constant [0,255].
    // As we're working with the scaled dimensions we need to scale the texture
    // image when displaying.
    final scaleToTextMultX = textWidth / tileWidth;
    final scaleToTextMultY = textHeight / tileHeight;

    // Get the amount of vertices in mesh
    // We are subtracting one as we are working with the faces,
    // not the vertices. We then multiply the number of faces by the
    // number of vertices per face to get total vertex count.
    final int vertexCount = ((clipTileWidth - 1) / increment).ceil() *
        ((clipTileHeight - 1) / increment).ceil() *
        faceVertexCount;

//    print("New mesh:");
//    print("    Vertex list size is: $vertexCount");
//    print("    Number of faces is: " +
//        (vertexCount / faceVertexCount).toString());
//    print("    Base WidthHeight: ($width, $height)");
//    print("    Initial LeftTop: ($left, $top)");
//    print("    Initial WidthHeight: ($tileWidth, $tileHeight)");
//    print("    Clip LeftTop: ($clipLeft, $clipTop)");
//    print("    Clip WidthHeight: ($clipTileWidth, $clipTileHeight)");

//    print("    " + CustomPoint((width~/2), (height~/2)-300).toString() + " to " + spherize.getPoint((width~/2), (height~/2)-300).toString());
//    print("    " + CustomPoint((width~/2), (height~/2)-100).toString() + " to " + spherize.getPoint((width~/2), (height~/2)-100).toString());
//    print("    " + CustomPoint((width~/2), (height~/2)+100).toString() + " to " + spherize.getPoint((width~/2), (height~/2)+100).toString());
//    print("    " + CustomPoint((width~/2), (height~/2)+300).toString() + " to " + spherize.getPoint((width~/2), (height~/2)+300).toString());

    // The list of vertices
    Float32List vertexList = Float32List(vertexCount);
    Float32List textCoords = Float32List(vertexCount);
    Int32List rgbaList = Int32List(vertexCount ~/ 2);

    // It it more efficient and easier to use an index variable
    // Rather than recalculate the index each iteration
    int index = 0;
    int colourIndex = 0;

    // The increment variable is dynamic as we may have a smaller face for
    // the last row/column of the mesh to fit the meshes nicely together.
    int dynamicXInc = increment;
    int dynamicYInc = increment;

    var rng = new Random();
    tile.setTestColour(Color.fromARGB(
        125, rng.nextInt(255), rng.nextInt(255), rng.nextInt(255)));

    // for each grid face calculate the spherized vertices
    for (int y = clipTop + dynamicYInc;
        y < clipTileHeight + clipTop;
        y += dynamicYInc) {
      for (int x = clipLeft + dynamicXInc;
          (x < clipTileWidth + clipLeft);
          x += dynamicXInc) {
//        print("        $index, $facecount: (" +
//            ((x - clipLeft) - dynamicXInc).toString() +
//            ", " +
//            ((y - clipTop) - dynamicYInc).toString() +
//            ") to (" +
//            ((x - clipLeft)).toString() +
//            ", " +
//            ((y - clipTop)).toString() +
//            ")");

        var topLeft = spherize.getPoint((x - dynamicXInc), (y - dynamicYInc),
            offsetX, offsetY, spherizeEffect);
        var bottomLeft = spherize.getPoint(
            x - dynamicXInc, y, offsetX, offsetY, spherizeEffect);
        var topRight = spherize.getPoint(
            x, y - dynamicYInc, offsetX, offsetY, spherizeEffect);
        var bottomRight =
            spherize.getPoint(x, y, offsetX, offsetY, spherizeEffect);

//        print("    " + CustomPoint(x - dynamicXInc, y - dynamicYInc).toString() + " to " + topLeft.toString());
//
//        print("\n\n    " +
//            topLeft.toString() +
//            "\n    " +
//            bottomLeft.toString() +
//            "\n    " +
//            topRight.toString() +
//            "\n    " +
//            bottomRight.toString());

        //Top left (triangle 1)
        vertexList[index + 0] = topLeft.x;
        vertexList[index + 1] = topLeft.y;
        textCoords[index + 0] =
            (((x + xOffset) - dynamicXInc) * scaleToTextMultX).toDouble();
        textCoords[index + 1] =
            (((y + yOffset) - dynamicYInc) * scaleToTextMultY).toDouble();
        //Bottom left (triangle 1)
        vertexList[index + 2] = bottomLeft.x;
        vertexList[index + 3] = bottomLeft.y;
        textCoords[index + 2] =
            (((x + xOffset) - dynamicXInc) * scaleToTextMultX).toDouble();
        textCoords[index + 3] = ((y + yOffset) * scaleToTextMultY).toDouble();
        //Bottom right (triangle 1)
        vertexList[index + 4] = bottomRight.x;
        vertexList[index + 5] = bottomRight.y;
        textCoords[index + 4] = ((x + xOffset) * scaleToTextMultX).toDouble();
        textCoords[index + 5] = ((y + yOffset) * scaleToTextMultY).toDouble();
        //Bottom right (triangle 2)
        vertexList[index + 6] = bottomRight.x;
        vertexList[index + 7] = bottomRight.y;
        textCoords[index + 6] = ((x + xOffset) * scaleToTextMultX).toDouble();
        textCoords[index + 7] = ((y + yOffset) * scaleToTextMultY).toDouble();
        //Top right (triangle 2)
        vertexList[index + 8] = topRight.x;
        vertexList[index + 9] = topRight.y;
        textCoords[index + 8] = ((x + xOffset) * scaleToTextMultX).toDouble();
        textCoords[index + 9] =
            (((y + yOffset) - dynamicYInc) * scaleToTextMultY).toDouble();
        //Top left (triangle 2)
        vertexList[index + 10] = topLeft.x;
        vertexList[index + 11] = topLeft.y;
        textCoords[index + 10] =
            (((x + xOffset) - dynamicXInc) * scaleToTextMultX).toDouble();
        textCoords[index + 11] =
            (((y + yOffset) - dynamicYInc) * scaleToTextMultY).toDouble();

        var addColour = Color.fromARGB(0, 0, 0, 0).value;
        if (dynamicXInc != increment) {
          addColour += Color.fromARGB(25, 0, 0, 0).value;
        }

        if (dynamicYInc != increment) {
          addColour += Color.fromARGB(25, 0, 0, 0).value;
        }

        rgbaList[colourIndex + 0] = tile.testColour.value +
            addColour; //Color.fromARGB(0, 255, 255, 255).value;
        rgbaList[colourIndex + 1] = tile.testColour.value +
            addColour; //Color.fromARGB(255, 255, 255, 255).value;
        rgbaList[colourIndex + 2] = tile.testColour.value +
            addColour; //Color.fromARGB(0, 255, 255, 255).value;

        rgbaList[colourIndex + 3] = tile.testColour.value +
            addColour; //Color.fromARGB(0, 255, 255, 255).value;
        rgbaList[colourIndex + 4] = tile.testColour.value +
            addColour; //Color.fromARGB(255, 255, 255, 255).value;
        rgbaList[colourIndex + 5] = tile.testColour.value +
            addColour; //Color.fromARGB(0, 255, 255, 255).value;

        index += 12;
        colourIndex += 6;

        if (x < clipTileWidth + clipLeft - 1 &&
            x + increment >= clipTileWidth + clipLeft) {
          dynamicXInc = (clipTileWidth + clipLeft - 1) - x;
        } else {
          dynamicXInc = increment;
        }
      }
      if (y < clipTileHeight + clipTop - 1 &&
          y + increment >= clipTileHeight + clipTop) {
        dynamicYInc = (clipTileHeight + clipTop - 1) - y;
      } else {
        dynamicYInc = increment;
      }
    }
//    print("    index finished at " + (index).toString());
//    print("    number of visited faces is $facecount");

    final vertices =
        Vertices.raw(VertexMode.triangles, vertexList, //colors: rgbaList);
            textureCoordinates: textCoords);

    final paint = Paint();
    Float64List matrix4 = new Matrix4.identity().storage;
    final shader = ImageShader(
        tile.imageInfo.image, TileMode.mirror, TileMode.mirror, matrix4);
    paint.shader = shader;
    canvas.drawVertices(vertices, BlendMode.src, paint);
  }

  Float32List _buildVertexRect(
      double left, double top, double right, double bottom) {
    final int vertexCount = 12;
    Float32List vertexList = Float32List(vertexCount);
    // Top left (triangle 1)
    vertexList[0] = left;
    vertexList[1] = top;
    // Bottom Left (triangle 1)
    vertexList[2] = left;
    vertexList[3] = bottom;
    // Bottom Right (triangle 1)
    vertexList[4] = right;
    vertexList[5] = bottom;
    // Bottom Right (triangle 2)
    vertexList[6] = right;
    vertexList[7] = bottom;
    // Top right (triangle 2)
    vertexList[8] = right;
    vertexList[9] = top;
    // Top left (triangle 2)
    vertexList[10] = left;
    vertexList[11] = top;

    return vertexList;
  }

  void _drawRect(Canvas canvas, Offset offset, Size size) {
    var paint = Paint()
      ..color = Color.fromARGB(255, 40, 95, 131)
      ..style = PaintingStyle.fill;
    //a rectangle
    canvas.drawRect(offset & size, paint);
  }

  void _drawImage(Canvas canvas, ui.Image image, double left, double top,
      double right, double bottom, double cropX, double cropY) {
    final int vertexCount = 12;
    Float32List vertexList = _buildVertexRect(left, top, right, bottom);
    Float32List textCoords = Float32List(vertexCount);

    final double imageWidth = image.width.toDouble();
    final double imageHeight = image.width.toDouble();

    // Top left (triangle 1)
    textCoords[0] = 0 + cropX;
    textCoords[1] = 0 + cropY;
    // Bottom Left (triangle 1)
    textCoords[2] = 0 + cropX;
    textCoords[3] = imageHeight - cropY;
    // Bottom Right (triangle 1)
    textCoords[4] = imageWidth - cropX;
    textCoords[5] = imageHeight - cropX;
    // Bottom Right (triangle 2)
    textCoords[6] = imageWidth - cropX;
    textCoords[7] = imageHeight - cropX;
    // Top right (triangle 2)
    textCoords[8] = imageWidth - cropX;
    textCoords[9] = 0 + cropY;
    // Top left (triangle 2)
    textCoords[10] = 0 + cropX;
    textCoords[11] = 0 + cropY;

    final vertices = Vertices.raw(VertexMode.triangles, vertexList,
        textureCoordinates: textCoords);

    final paint = Paint();
    Float64List matrix4 = new Matrix4.identity().storage;
    final shader =
        ImageShader(image, TileMode.mirror, TileMode.mirror, matrix4);
    paint.shader = shader;
    canvas.drawVertices(vertices, BlendMode.src, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (tiles == null) return;

    // This will be the size of the earth rect
    var baseWidth = size.width.toInt();
    var baseHeight = size.height.toInt();
    var topOffset = (size.height - scaledSize.height) ~/ 2;
    for (var tile in tiles) {
      if (tile.loadError == false &&
          tile.imageInfo?.image != null &&
          tile.opacity < 255) {
        // 1 is added to the scaled width/height as a gross solution
        // to remove the white bordering from tiles.
        // To future me or whomever reads this, im pretty sure the bug
        // is as a result of integers used rather than doubles.
        var scaledWidth = (tileSize.width * tile.level.scale).ceil() + 1;
        var scaledHeight = (tileSize.height * tile.level.scale).ceil() + 1;
        var pos = (tile.tilePos).multiplyBy(tile.level.scale) +
            tile.level.translatePoint;

        // Will the tile at all be visible on screen?
        // If yes then calculate the mesh and render
        if ((0 < pos.x.toInt() + scaledWidth &&
            pos.x.toInt() < baseWidth &&
            0 < pos.y.toInt() + scaledHeight &&
            pos.y.toInt() < baseHeight)) {
          _drawTileMesh(
              canvas,
              tile,
              pos.x.toInt(),
              pos.y.toInt(),
              scaledWidth,
              scaledHeight,
              baseWidth,
              baseHeight,
              tileSize.width.toInt(),
              tileSize.height.toInt(),
              25,
              spherize,
              0,
              0);
        }
      }
    }

//    final double outOfBoundsX = baseWidth / 2;
//    final double outOfBoundsY = baseHeight / 2;
    var halfWidth = size.width / 2;
    var halfHeight = size.height / 2;

    // sperize effect 1 : sphere effect
    // spherize effect 0 : no effect
    // Adjust left offset is 0 when sphere effect
    // Adjust left offset is -halfWidth when no sphere effect

    var adjustLeftOffset = -halfWidth * (1 - spherizeEffect);
    var adjustTopOffset =
        ((topOffset.toDouble() + halfHeight) * spherizeEffect) - halfHeight;

    // Draw the circular outline image over the map
    // args : left top right bottom cropx cropy
    _drawImage(canvas, sphereOverlay, adjustLeftOffset, adjustTopOffset,
        size.width - adjustLeftOffset, size.height - adjustTopOffset, 10, 10);

    // Draw the colour bars at the top and bottom
    _drawRect(canvas, Offset(0, 0), Size(size.width, adjustTopOffset));
    _drawRect(canvas, Offset(0, size.height - adjustTopOffset),
        Size(size.width, size.height));
  }

  void basicMap(Canvas canvas, Size size) {
    if (tiles == null) return;

//    int baseWidth = size.width.toInt();
//    int baseHeight = size.height.toInt();
    for (Tile tile in tiles) {
      if (tile.loadError == false &&
          tile.imageInfo?.image != null &&
          tile.opacity < 255) {
        double scaledWidth = (tileSize.width * tile.level.scale);
        double scaledHeight = (tileSize.height * tile.level.scale);
        CustomPoint pos = (tile.tilePos).multiplyBy(tile.level.scale) +
            tile.level.translatePoint;

        // 6 points for 2 triangles (square). 2 floats per point.
        final int vertexCount = 12;
        Float32List vertexList = Float32List(vertexCount);
        Float32List textCoords = Float32List(vertexCount);
        //Top left (triangle 1)
        vertexList[0] = pos.x;
        vertexList[1] = pos.y;
        textCoords[0] = 0;
        textCoords[1] = 0;
        //Bottom left (triangle 1)
        vertexList[2] = pos.x;
        vertexList[3] = pos.y + scaledHeight;
        textCoords[2] = 0;
        textCoords[3] = tileSize.height;
        //Bottom right (triangle 1)
        vertexList[4] = pos.x + scaledWidth;
        vertexList[5] = pos.y + scaledHeight;
        textCoords[4] = tileSize.width;
        textCoords[5] = tileSize.height;
        //Bottom right (triangle 2)
        vertexList[6] = pos.x + scaledWidth;
        vertexList[7] = pos.y + scaledHeight;
        textCoords[6] = tileSize.width;
        textCoords[7] = tileSize.height;
        //Top right (triangle 2)
        vertexList[8] = pos.x + scaledHeight;
        vertexList[9] = pos.y;
        textCoords[8] = tileSize.width;
        textCoords[9] = 0;
        //Top left (triangle 2)
        vertexList[10] = pos.x;
        vertexList[11] = pos.y;
        textCoords[10] = 0;
        textCoords[11] = 0;

        final vertices = Vertices.raw(VertexMode.triangles, vertexList,
            textureCoordinates: textCoords);

        final paint = Paint();
        Float64List matrix4 = new Matrix4.identity().storage;
        final shader = ImageShader(
            tile.imageInfo.image, TileMode.mirror, TileMode.mirror, matrix4);
        paint.shader = shader;
        canvas.drawVertices(vertices, BlendMode.src, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class SphereClipper extends CustomClipper<Rect> {
//  final double heightScale;

//  SphereClipper(this.heightScale);

  Rect getClip(Size size) {
//    var scaledSize = Size(size.width, (size.height * 0.7).toInt().toDouble());
//    var topOffset = (size.height - scaledSize.height) / 2;
//    return Rect.fromLTWH(0, topOffset, scaledSize.width, scaledSize.height);
    return Rect.fromLTWH(1, 1, size.width - 1, size.height - 1);
  }

  bool shouldReclip(oldClipper) {
    return false;
  }
}

int interpolate(int oldPos, int oldLength, int newLength) {
  return ((oldPos / oldLength) * newLength).toInt();
}
