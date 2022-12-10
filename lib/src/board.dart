library stack_board;

import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:stack_board/stack_board.dart';

import 'case_group/adaptive_text_case.dart';
import 'case_group/drawing_board_case.dart';

/// 层叠板
class StackBoard extends StatefulWidget {
  const StackBoard({
    Key? key,
    this.controller,
    this.background,
    this.caseStyle = const CaseStyle(),
    this.customBuilder,
    this.tapToCancelAllItem = false,
    this.tapItemToMoveTop = true,
  }) : super(key: key);

  @override
  _StackBoardState createState() => _StackBoardState();

  /// 层叠版控制器
  final StackBoardController? controller;

  /// 背景
  final Widget? background;

  /// 操作框样式
  final CaseStyle? caseStyle;

  /// 自定义类型控件构建器
  final Widget? Function(StackBoardItem item)? customBuilder;

  /// 点击空白处取消全部选择（比较消耗性能，默认关闭）
  final bool tapToCancelAllItem;

  /// 点击item移至顶层
  final bool tapItemToMoveTop;
}

class _StackBoardState extends State<StackBoard> with SafeState<StackBoard> {
  /// 子控件列表
  late List<StackBoardItem> _children;

  final Map<int, ItemInfo> _mapInfo = {};

  final Map<int, GlobalKey<ItemCaseState>> _mapKey = {};

  /// 当前item所用id
  int _lastId = 0;

  /// 所有item的操作状态
  OperatState? _operaState;

  /// 生成唯一Key
  Key _getKey(int? id) => Key('StackBoardItem$id');

  @override
  void initState() {
    super.initState();
    _children = <StackBoardItem>[];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller?._stackBoardState = this;
  }

  /// 添加一个
  void _add<T extends StackBoardItem>(StackBoardItem item) {
    print('xxxxxx $item - ${_children.contains(item)}');
    if (_children.contains(item)) throw 'duplicate id';

    _children.add(item.copyWith(
      id: item.id ?? _lastId,
      caseStyle: item.caseStyle ?? widget.caseStyle,
    ));

    _lastId++;
    safeSetState(() {});
  }

  /// 移除指定id item
  void _remove(int? id) {
    _mapInfo.remove(id);
    _children.removeWhere((StackBoardItem b) => b.id == id);
    safeSetState(() {});
  }

  /// 将item移至顶层
  void _moveItemToTop(int? id) {
    if (id == null) return;

    final StackBoardItem item =
        _children.firstWhere((StackBoardItem i) => i.id == id);
    _children.removeWhere((StackBoardItem i) => i.id == id);
    _children.add(item);

    safeSetState(() {});
  }

  /// 清理
  void _clear() {
    _children.clear();
    _lastId = 0;
    safeSetState(() {});
  }

  /// 取消全部选中
  void _unFocus() {
    _operaState = OperatState.complate;
    safeSetState(() {});
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      _operaState = null;
      safeSetState(() {});
    });
  }

  /// 删除动作
  Future<void> _onDel(StackBoardItem box) async {
    final bool del = (await box.onDel?.call()) ?? true;
    if (del) _remove(box.id);
  }

  @override
  Widget build(BuildContext context) {
    Widget _child;

    if (widget.background == null)
      _child = Stack(
        fit: StackFit.expand,
        children:
            _children.map((StackBoardItem box) => _buildItem(box)).toList(),
      );
    else
      _child = Stack(
        fit: StackFit.expand,
        children: <Widget>[
          widget.background!,
          ..._children.map((StackBoardItem box) => _buildItem(box)).toList(),
        ],
      );

    if (widget.tapToCancelAllItem) {
      _child = GestureDetector(
        onTap: _unFocus,
        child: _child,
      );
    }

    return _child;
  }

  bool onAngleChanged(StackBoardItem item, double value) {
    final int? id = item.id;
    if(id != null) {
      final ItemInfo? info = _mapInfo[id];
      if(info != null) {
        info.rotation = value;
      } else {
        _mapInfo.putIfAbsent(id, () => ItemInfo(height: 0, width: 0, x: 0, y: 0, id: id, rotation: value));
      }
    }
    return true;
  }

  /// 构建项
  Widget _buildItem(StackBoardItem item) {
    final Key key = _getKey(item.id);
    final GlobalKey<ItemCaseState> _globalKey = GlobalKey<ItemCaseState>();
    final int? id = item.id;
    if(id != null) {
      _mapKey.putIfAbsent(id, () => _globalKey);
    }
    Widget child = ItemCase(
      globalKey: _globalKey,
      key: key,
      child: Container(
        width: 150,
        height: 150,
        alignment: Alignment.center,
        child: const Text(
            'unknown item type, please use customBuilder to build it'),
      ),
      onDel: () => _onDel(item),
      onTap: () => _moveItemToTop(item.id),
      caseStyle: item.caseStyle,
      operatState: _operaState,
      onAngleChanged: (double value) => onAngleChanged(item, value),
    );

    if (item is AdaptiveText) {
      child = AdaptiveTextCase(
        globalKey: _globalKey,
        key: key,
        adaptiveText: item,
        onDel: () => _onDel(item),
        onTap: () => _moveItemToTop(item.id),
        operatState: _operaState,
        onAngleChanged: (double value) => onAngleChanged(item, value),
      );
    } else if (item is StackDrawing) {
      child = DrawingBoardCase(
        globalKey: _globalKey,
        key: key,
        stackDrawing: item,
        onDel: () => _onDel(item),
        onTap: () => _moveItemToTop(item.id),
        operatState: _operaState,
        onAngleChanged: (double value) => onAngleChanged(item, value),
      );
    } else {
      child = ItemCase(
        globalKey: _globalKey,
        key: key,
        child: item.child,
        onDel: () => _onDel(item),
        onTap: () => _moveItemToTop(item.id),
        caseStyle: item.caseStyle,
        operatState: _operaState,
        onAngleChanged: (double value) => onAngleChanged(item, value),
      );

      if (widget.customBuilder != null) {
        final Widget? customWidget = widget.customBuilder!.call(item);
        if (customWidget != null) return child = customWidget;
      }
    }
    return child;
  }

  Map<int, ItemInfo> getMapInfo() {
    _mapKey.forEach((int id, GlobalKey _globalKey) {
      Size _size = const Size(0, 0);
      Offset _offset = const Offset(0, 0);
      final RenderObject? _obj = _globalKey.currentContext?.findRenderObject();
      if(_obj != null) {
        final RenderBox _box = _obj as RenderBox;
        _offset = _box.localToGlobal(Offset.zero);
        _size = _box.size;
      }
      final ItemInfo? _itemInfo = _mapInfo[id];
      if(_itemInfo != null) {
        _itemInfo.width = _size.width;
        _itemInfo.height = _size.height;
        _itemInfo.x = _offset.dx;
        _itemInfo.y = _offset.dy;
        _mapInfo.putIfAbsent(id, () => _itemInfo);
      } else {
        _mapInfo.putIfAbsent(id, () => ItemInfo(
          id: id, 
          height: _size.height, 
          width: _size.width, 
          x: _offset.dx, 
          y: _offset.dy, 
          rotation: 0
        ));
      }
    });
    return _mapInfo;
  }
}

/// 控制器
class StackBoardController {
  _StackBoardState? _stackBoardState;

  /// 检查是否加载
  void _check() {
    if (_stackBoardState == null) throw '_stackBoardState is empty';
  }

  /// 添加一个
  void add<T extends StackBoardItem>(T item) {
    _check();
    _stackBoardState?._add<T>(item);
  }

  /// 移除
  void remove(int? id) {
    _check();
    _stackBoardState?._remove(id);
  }

  void moveItemToTop(int? id) {
    _check();
    _stackBoardState?._moveItemToTop(id);
  }

  /// 清理全部
  void clear() {
    _check();
    _stackBoardState?._clear();
  }

  /// 刷新
  void refresh() {
    _check();
    _stackBoardState?.safeSetState(() {});
  }

  /// 销毁
  void dispose() {
    _stackBoardState = null;
  }

  List<ItemInfo> getItemInfos() {
    return _stackBoardState?.getMapInfo().values.toList() ?? [];
  }
}

class ItemInfo {
  ItemInfo({ required this.height, required this.width, required this.x, required this.y, required this.id, required this.rotation });
  int id;
  double x;
  double y;
  double width;
  double height;
  double rotation;

  @override
  String toString() {
    return "{ id: $id, x: $x, y: $y, width: $width, height: $height, rotation: $rotation }";
  }
}