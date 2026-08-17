import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class CallerOverlayPage extends StatefulWidget {
  const CallerOverlayPage({super.key});

  @override
  State<CallerOverlayPage> createState() => _CallerOverlayPageState();
}

class _CallerOverlayPageState extends State<CallerOverlayPage> {
  StreamSubscription<dynamic>? _subscription;
  String _phone = '';
  List<String> _names = const [];
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _subscription = FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is! Map) return;
      final rawName = data['name']?.toString() ?? '';
      if (!mounted) return;

      setState(() {
        _phone = data['phone']?.toString() ?? '';
        _names = rawName
            .split(RegExp(r'[,،|]'))
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _close() => FlutterOverlayWindow.closeOverlay();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: _expanded ? _buildExpanded() : _buildCollapsed(),
        ),
      ),
    );
  }

  Widget _buildCollapsed() {
    return GestureDetector(
      onTap: () => setState(() => _expanded = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _close,
              icon: const Icon(Icons.close, color: Colors.black),
            ),
            const Icon(Icons.search, color: Color(0xFF0A5C66)),
            const SizedBox(width: 10),
            Text(
              _phone.isEmpty ? 'رقم غير معروف' : _phone,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            const CircleAvatar(
              backgroundColor: Color(0xFF0A5C66),
              child: Icon(Icons.security, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _close,
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
              Text(
                _phone,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A5C66),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _expanded = false),
                icon: const Icon(Icons.keyboard_arrow_up, color: Colors.grey),
              ),
            ],
          ),
          const Divider(),
          if (_names.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'رقم غير مسجل',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          else
            ..._names.map(
              (name) => ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF0A5C66)),
                title: Text(name, textAlign: TextAlign.right),
              ),
            ),
        ],
      ),
    );
  }
}
