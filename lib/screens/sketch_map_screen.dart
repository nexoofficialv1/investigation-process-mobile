import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../models/pending_cd_action.dart';
import '../models/sketch_map.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';
import 'pdf_preview_screen.dart';

class SketchMapScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const SketchMapScreen({super.key, required this.profile, required this.caseFile});

  @override
  State<SketchMapScreen> createState() => _SketchMapScreenState();
}

class _SketchMapScreenState extends State<SketchMapScreen> {
  final LocalStoreService _store = LocalStoreService();
  final PdfService _pdf = PdfService();

  late SketchMapEntry _map;
  final _poCtrl = TextEditingController();
  final _northCtrl = TextEditingController();
  final _southCtrl = TextEditingController();
  final _eastCtrl = TextEditingController();
  final _westCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _map = SketchMapEntry.empty(caseId: widget.caseFile.id);
    _load();
  }

  Future<void> _load() async {
    final saved = await _store.loadSketchMap(widget.caseFile.id);
    if (!mounted) return;
    setState(() {
      _map = saved ?? SketchMapEntry.empty(caseId: widget.caseFile.id);
      _poCtrl.text = _map.poDescription;
      _northCtrl.text = _map.north;
      _southCtrl.text = _map.south;
      _eastCtrl.text = _map.east;
      _westCtrl.text = _map.west;
    });
  }

  @override
  void dispose() {
    _poCtrl.dispose();
    _northCtrl.dispose();
    _southCtrl.dispose();
    _eastCtrl.dispose();
    _westCtrl.dispose();
    super.dispose();
  }

  String _nextMarker() {
    final used = _map.objects.map((e) => e.marker).toSet();
    for (var i = 0; i < 26; i++) {
      final mark = String.fromCharCode(65 + i);
      if (!used.contains(mark)) return mark;
    }
    return '${_map.objects.length + 1}';
  }

  void _addObject(SketchObjectType type) {
    final offset = (_map.objects.length % 6) * 0.055;
    final obj = SketchMapObject.create(
      type: type,
      marker: _nextMarker(),
      x: (0.18 + offset).clamp(0.02, 0.82),
      y: (0.20 + offset).clamp(0.02, 0.82),
    );
    setState(() => _map = _map.copyWith(objects: [..._map.objects, obj]));
  }

  void _updateObject(SketchMapObject obj) {
    setState(() {
      _map = _map.copyWith(
        objects: _map.objects.map((e) => e.id == obj.id ? obj : e).toList(),
      );
    });
  }

  void _deleteObject(SketchMapObject obj) {
    setState(() => _map = _map.copyWith(objects: _map.objects.where((e) => e.id != obj.id).toList()));
  }

  SketchMapEntry _currentMap() => _map.copyWith(
        poDescription: _poCtrl.text.trim(),
        north: _northCtrl.text.trim(),
        south: _southCtrl.text.trim(),
        east: _eastCtrl.text.trim(),
        west: _westCtrl.text.trim(),
      );

  Future<void> _save({bool askCd = false}) async {
    final updated = _currentMap();
    await _store.saveSketchMap(updated);
    if (!mounted) return;
    setState(() => _map = updated);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sketch map saved')));
    if (askCd) await _askMentionInCd();
  }

  Future<void> _askMentionInCd() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mention in Case Diary?'),
        content: const Text('Prepared rough sketch map with index — এই action-টা CD-তে mention করা হবে?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    if (yes != true) return;
    final action = PendingCdAction.create(
      caseId: widget.caseFile.id,
      sourceType: 'Sketch Map',
      sourceId: _map.id,
      title: 'Rough Sketch Map prepared',
      actionDate: _map.date,
      paragraph: 'Prepared rough sketch map of the PO with index.',
    );
    await _store.savePendingCdAction(action);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CD pending entry created')));
  }

  Future<void> _preview() async {
    await _save();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: 'Preview Sketch Map',
          filename: 'Sketch_Map_${widget.caseFile.psCaseNo.replaceAll('/', '_')}.pdf',
          buildPdf: () => _pdf.buildSketchMapPdf(officer: widget.profile, caseFile: widget.caseFile, sketch: _currentMap()),
          onFinalSave: () async => _save(askCd: true),
        ),
      ),
    );
  }

  Future<void> _editObjectDialog(SketchMapObject obj) async {
    final labelCtrl = TextEditingController(text: obj.label);
    final indexCtrl = TextEditingController(text: obj.indexDescription);
    String direction = obj.direction;
    final result = await showDialog<SketchMapObject?>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('${obj.marker} - ${obj.type.label}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Map label e.g. A (House)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: direction.isEmpty ? null : direction,
                  decoration: const InputDecoration(labelText: 'Direction for index'),
                  items: const ['North', 'South', 'East', 'West', 'Inside PO', 'Near PO']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setLocal(() => direction = v ?? ''),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: indexCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Index description e.g. East - A - House of ...'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel'))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(
                          context,
                          obj.copyWith(label: labelCtrl.text.trim(), direction: direction, indexDescription: indexCtrl.text.trim()),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteObject(obj);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete this object'),
                )
              ],
            ),
          ),
        ),
      ),
    );
    labelCtrl.dispose();
    indexCtrl.dispose();
    if (result != null) _updateObject(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Sketch Map Builder')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _save(), icon: const Icon(Icons.save), label: const Text('Save'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(onPressed: _preview, icon: const Icon(Icons.picture_as_pdf), label: const Text('Preview'))),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _caseCard(),
          const SizedBox(height: 10),
          _toolbar(),
          const SizedBox(height: 10),
          _canvas(),
          const SizedBox(height: 12),
          _poAndDirections(),
          const SizedBox(height: 12),
          _indexList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _caseCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.caseFile.displayTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text('PO: ${widget.caseFile.placeOfOccurrence.isEmpty ? 'Not mentioned' : widget.caseFile.placeOfOccurrence}'),
            const SizedBox(height: 4),
            const Text('Object button চাপুন → map-এ বসবে → আঙুল দিয়ে drag করুন → tap করে label/index লিখুন।', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _toolbar() {
    final items = [
      _SketchTool(SketchObjectType.house, Icons.home, 'House'),
      _SketchTool(SketchObjectType.pond, Icons.water, 'Pond'),
      _SketchTool(SketchObjectType.tree, Icons.park, 'Tree'),
      _SketchTool(SketchObjectType.shop, Icons.store, 'Shop'),
      _SketchTool(SketchObjectType.road, Icons.add_road, 'Road'),
      _SketchTool(SketchObjectType.field, Icons.crop_square, 'Field'),
      _SketchTool(SketchObjectType.po, Icons.location_on, 'PO'),
      _SketchTool(SketchObjectType.arrow, Icons.navigation, 'North'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((e) => ActionChip(
                    avatar: Icon(e.icon, size: 18),
                    label: Text(e.label),
                    onPressed: () => _addObject(e.type),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _canvas() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF004D40),
            child: const Text('Rough Sketch Canvas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          AspectRatio(
            aspectRatio: 1.05,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Container(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      Positioned(top: 8, right: 12, child: _northMark()),
                      ..._map.objects.map((obj) => _sketchObjectWidget(obj, w, h)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _northMark() => const Column(
        children: [
          Icon(Icons.navigation, color: Colors.black87),
          Text('N', style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      );

  Widget _sketchObjectWidget(SketchMapObject obj, double w, double h) {
    final left = obj.x * w;
    final top = obj.y * h;
    final width = obj.width * w;
    final height = obj.height * h;
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _editObjectDialog(obj),
        onPanUpdate: (details) {
          final nx = (((left + details.delta.dx) / w).clamp(0.0, 0.92)).toDouble();
          final ny = (((top + details.delta.dy) / h).clamp(0.0, 0.92)).toDouble();
          _updateObject(obj.copyWith(x: nx, y: ny));
        },
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: _objectColor(obj.type),
            border: Border.all(color: obj.type == SketchObjectType.po ? Colors.red.shade800 : Colors.black87, width: obj.type == SketchObjectType.po ? 2 : 1),
            borderRadius: obj.type == SketchObjectType.tree || obj.type == SketchObjectType.po ? BorderRadius.circular(80) : BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(3),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_objectIcon(obj.type), size: 22, color: obj.type == SketchObjectType.po ? Colors.red.shade900 : Colors.black87),
                Text(obj.marker, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(obj.label, textAlign: TextAlign.center, maxLines: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _objectColor(SketchObjectType type) {
    switch (type) {
      case SketchObjectType.house:
        return Colors.orange.shade100;
      case SketchObjectType.pond:
        return Colors.blue.shade100;
      case SketchObjectType.tree:
        return Colors.green.shade100;
      case SketchObjectType.shop:
        return Colors.purple.shade100;
      case SketchObjectType.road:
        return Colors.grey.shade300;
      case SketchObjectType.field:
        return Colors.lime.shade100;
      case SketchObjectType.po:
        return Colors.red.shade50;
      case SketchObjectType.arrow:
        return Colors.white;
    }
  }

  IconData _objectIcon(SketchObjectType type) {
    switch (type) {
      case SketchObjectType.house:
        return Icons.home;
      case SketchObjectType.pond:
        return Icons.water;
      case SketchObjectType.tree:
        return Icons.park;
      case SketchObjectType.shop:
        return Icons.store;
      case SketchObjectType.road:
        return Icons.add_road;
      case SketchObjectType.field:
        return Icons.crop_square;
      case SketchObjectType.po:
        return Icons.location_on;
      case SketchObjectType.arrow:
        return Icons.navigation;
    }
  }

  Widget _poAndDirections() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PO & Surroundings / Direction Index', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            TextField(controller: _poCtrl, decoration: const InputDecoration(labelText: 'PO description')),
            const SizedBox(height: 8),
            TextField(controller: _northCtrl, decoration: const InputDecoration(labelText: 'North')),
            TextField(controller: _southCtrl, decoration: const InputDecoration(labelText: 'South')),
            TextField(controller: _eastCtrl, decoration: const InputDecoration(labelText: 'East')),
            TextField(controller: _westCtrl, decoration: const InputDecoration(labelText: 'West')),
          ],
        ),
      ),
    );
  }

  Widget _indexList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Object Index', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            if (_map.objects.isEmpty)
              const Text('No object added yet. Add House/Pond/Road/PO etc.')
            else
              ..._map.objects.map((o) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text(o.marker)),
                    title: Text(o.label),
                    subtitle: Text('${o.direction.isEmpty ? 'Direction not set' : o.direction} • ${o.indexDescription.isEmpty ? 'Index description not set' : o.indexDescription}'),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _editObjectDialog(o),
                  )),
          ],
        ),
      ),
    );
  }
}

class _SketchTool {
  final SketchObjectType type;
  final IconData icon;
  final String label;
  const _SketchTool(this.type, this.icon, this.label);
}
