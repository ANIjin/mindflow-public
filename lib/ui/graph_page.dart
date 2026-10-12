import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../core/models/node.dart';
import 'shell_state.dart';
import 'tokens.dart';

class GraphViewPage extends StatefulWidget {
  const GraphViewPage({super.key});

  @override
  State<GraphViewPage> createState() => _GraphViewPageState();
}

class _GraphViewPageState extends State<GraphViewPage> {
  String? _typeFilter;
  String? _tagFilter;
  final _transform = TransformationController();
  late Map<String, Offset> _positions;
  late List<MindNode> _nodes;
  late List<(String, String)> _edges;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuild();
  }

  void _rebuild() {
    final state = context.read<AppState>();
    var nodes = state.store.nodes.values.toList();
    if (_typeFilter != null && _typeFilter!.isNotEmpty) {
      nodes = nodes.where((n) => n.type == _typeFilter).toList();
    }
    if (_tagFilter != null && _tagFilter!.isNotEmpty) {
      nodes = nodes.where((n) => n.tags.contains(_tagFilter)).toList();
    }
    if (nodes.length > 2000) {
      nodes = nodes.take(2000).toList();
    }
    final ids = nodes.map((n) => n.id).toSet();
    final edges = <(String, String)>[];
    for (final n in nodes) {
      for (final to in state.store.linkIndex.out[n.id] ?? const <String>{}) {
        if (ids.contains(to)) edges.add((n.id, to));
      }
    }
    _nodes = nodes;
    _edges = edges;
    _positions = _layout(nodes, edges);
  }

  Map<String, Offset> _layout(
      List<MindNode> nodes, List<(String, String)> edges) {
    final rnd = math.Random(42);
    final pos = <String, Offset>{
      for (final n in nodes)
        n.id: Offset(rnd.nextDouble() * 800 + 40, rnd.nextDouble() * 600 + 40)
    };
    // Simple force-directed iterations
    for (var iter = 0; iter < 40; iter++) {
      final disp = {for (final n in nodes) n.id: Offset.zero};
      for (var i = 0; i < nodes.length; i++) {
        for (var j = i + 1; j < nodes.length; j++) {
          final a = nodes[i].id;
          final b = nodes[j].id;
          final delta = pos[a]! - pos[b]!;
          final dist = delta.distance.clamp(1.0, 1000.0);
          final force = 8000 / (dist * dist);
          final push = Offset(delta.dx / dist * force, delta.dy / dist * force);
          disp[a] = disp[a]! + push;
          disp[b] = disp[b]! - push;
        }
      }
      for (final e in edges) {
        final delta = pos[e.$1]! - pos[e.$2]!;
        final dist = delta.distance.clamp(1.0, 1000.0);
        final force = (dist - 120) * 0.05;
        final pull = Offset(delta.dx / dist * force, delta.dy / dist * force);
        disp[e.$1] = disp[e.$1]! - pull;
        disp[e.$2] = disp[e.$2]! + pull;
      }
      for (final n in nodes) {
        final d = disp[n.id]!;
        final capped = Offset(d.dx.clamp(-40, 40), d.dy.clamp(-40, 40));
        pos[n.id] = pos[n.id]! + capped;
      }
    }
    return pos;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final shell = context.watch<ShellState>();
    final t = tk(context);
    _rebuild();

    return Column(
      key: const ValueKey('graph-view'),
      children: [
        Padding(
          padding: EdgeInsets.all(t.md),
          child: Row(
            children: [
              Text('Graph',
                  style: TextStyle(
                      fontSize: t.textHead,
                      fontWeight: FontWeight.w700,
                      color: t.label)),
              const Spacer(),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<String?>(
                  key: const ValueKey('graph-type-filter'),
                  value: _typeFilter,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...{
                      for (final n in state.store.nodes.values) n.type
                    }.map((type) => DropdownMenuItem(
                        value: type, child: Text(type))),
                  ],
                  onChanged: (v) => setState(() => _typeFilter = v),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: 0.3,
            maxScale: 3,
            child: CustomPaint(
              size: const Size(1200, 900),
              painter: _GraphPainter(
                nodes: _nodes,
                edges: _edges,
                positions: _positions,
                tokens: t,
              ),
              child: Stack(
                children: [
                  for (final n in _nodes)
                    Positioned(
                      left: (_positions[n.id]?.dx ?? 0) - 40,
                      top: (_positions[n.id]?.dy ?? 0) - 14,
                      child: GestureDetector(
                        key: ValueKey('graph-node-${n.id}'),
                        onTap: () => shell.openPage(n.id),
                        child: Container(
                          width: 80,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: t.elevated,
                            borderRadius: BorderRadius.circular(t.radiusSm),
                            border: Border.all(color: t.accent.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            n.title.isEmpty ? n.id : n.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: t.label),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<MindNode> nodes;
  final List<(String, String)> edges;
  final Map<String, Offset> positions;
  final Tokens tokens;

  _GraphPainter({
    required this.nodes,
    required this.edges,
    required this.positions,
    required this.tokens,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tokens.graphEdge
      ..strokeWidth = 1.2;
    for (final e in edges) {
      final a = positions[e.$1];
      final b = positions[e.$2];
      if (a == null || b == null) continue;
      canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) => true;
}
