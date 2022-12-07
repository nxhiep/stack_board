import 'package:flutter/widgets.dart';
import 'package:stack_board/src/helper/case_style.dart';

/// 自定义对象
@immutable
class StackBoardItem {
  const StackBoardItem({
    required this.child,
    this.id,
    this.onDel,
    this.caseStyle,
    this.tapToEdit = false,
  });

  /// key to get size, position
  /// item id
  final int? id;
  final Widget child;
  final Future<bool> Function()? onDel;
  /// Khung
  final CaseStyle? caseStyle;
  final bool tapToEdit;

  /// copy object
  StackBoardItem copyWith({
    int? id,
    Widget? child,
    Future<bool> Function()? onDel,
    CaseStyle? caseStyle,
    bool? tapToEdit,
  }) =>
      StackBoardItem(
        id: id ?? this.id,
        child: child ?? this.child,
        onDel: onDel ?? this.onDel,
        caseStyle: caseStyle ?? this.caseStyle,
        tapToEdit: tapToEdit ?? this.tapToEdit,
      );

  /// compare object
  bool sameWith(StackBoardItem item) => item.id == id;

  @override
  bool operator ==(Object other) => other is StackBoardItem && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
