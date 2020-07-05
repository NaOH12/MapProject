import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Spherize extends SingleChildRenderObjectWidget {
  const Spherize({
    Key key,
    @required this.effectVal,
    Widget child,
  }) : super(key: key, child: child);

  final double effectVal;

  @override
  RenderSpherize createRenderObject(BuildContext context) {
    return RenderSpherize(
      effectVal: effectVal,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSpherize renderObject) {
    renderObject..effectVal = effectVal;
  }

//  @override
//  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
//    super.debugFillProperties(properties);
//    properties.add(ColorProperty('color', color));
//  }
}

class RenderSpherize extends RenderProxyBox {
  RenderSpherize({
    double effectVal = 1.0,
    RenderBox child,
  })  : assert(effectVal != null),
        _effectVal = effectVal,
        super(child);

  double _effectVal;
  double get effectVal => _effectVal;
  set effectVal(double effectVal) {
    assert(effectVal >= 0.0 && effectVal <= 1.0);
    if (_effectVal == effectVal) return;
    _effectVal = effectVal;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      context.paintChild(child, offset);
    }
//    context.canvas.
//    context.canvas.drawColor(color, BlendMode.srcOver);
  }

//  @override
//  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
//    super.debugFillProperties(properties);
//    properties.add(ColorProperty('color', color));
//  }
}
