import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// A search bar that reports its text after the user pauses typing, so each keystroke does not hit the server.
class DebouncedSearch extends StatefulWidget {
  const DebouncedSearch({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.delay = const Duration(milliseconds: 300),
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final Duration delay;

  @override
  State<DebouncedSearch> createState() => _DebouncedSearchState();
}

class _DebouncedSearchState extends State<DebouncedSearch> {
  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    setState(() {});
    _timer?.cancel();
    _timer = Timer(widget.delay, () => widget.onChanged(value.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: _controller,
      hintText: widget.hintText,
      leading: const Icon(Icons.search),
      elevation: const WidgetStatePropertyAll(0),
      onChanged: _changed,
      trailing: [
        if (_controller.text.isNotEmpty)
          IconButton(
            tooltip: AppLocalizations.of(context).close,
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              _timer?.cancel();
              setState(() {});
              widget.onChanged('');
            },
          ),
      ],
    );
  }
}
