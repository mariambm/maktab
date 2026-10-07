import 'package:flutter/material.dart';

/// The first few items of a history, newest first, with a button to show the rest.
class RecentList<T> extends StatefulWidget {
  const RecentList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.showAllLabel,
    required this.showLessLabel,
    this.visible = 5,
  });

  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final String showAllLabel;
  final String showLessLabel;
  final int visible;

  @override
  State<RecentList<T>> createState() => _RecentListState<T>();
}

class _RecentListState<T> extends State<RecentList<T>> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final shown = _expanded ? items : items.take(widget.visible);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in shown) widget.itemBuilder(item),
        if (items.length > widget.visible)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? widget.showLessLabel : '${widget.showAllLabel} (${items.length})'),
            ),
          ),
      ],
    );
  }
}
