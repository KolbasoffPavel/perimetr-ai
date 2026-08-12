String? _error;Future<void> _importFrom(ImageSource source) async {final picker = ImagePicker();final XFile? picked = await picker.pickImage(source: source, imageQuality: 95);if (picked == null) return;setState(() {_importing = true;_error = null;});try {final sourceFile = File(picked.path);final dir = await getApplicationDocumentsDirectory();final panoramasDir = Directory('${dir.path}/panoramas');if (!await panoramasDir.exists()) {await panoramasDir.create(recursive: true);}final destPath = '${panoramasDir.path}/${widget.room.id}.jpg';await sourceFile.copy(destPath);if (mounted) {context.read<AppState>().saveRoomPanorama(widget.room.id, destPath);}} catch (e) {setState(() => _error = 'Не удалось загрузить панораму: $e');} finally {if (mounted) setState(() => _importing = false);}}void _showSourcePicker() {showModalBottomSheet(context: context,builder: (ctx) => SafeArea(child: Wrap(children: [ListTile(leading: const Icon(Icons.camera_alt_outlined),title: const Text('Снять камерой (режим «Панорама»)'),onTap: () {Navigator.pop(ctx);_importFrom(ImageSource.camera);},),ListTile(leading: const Icon(Icons.photo_library_outlined),title: const Text('Выбрать из галереи'),onTap: () {Navigator.pop(ctx);_importFrom(ImageSource.gallery);},),],),),);}void _deletePanorama() {showDialog(context: context,builder: (ctx) => AlertDialog(title: const Text('Удалить панораму?'),content: const Text('Снимок будет удалён из помещения. Это действие нельзя отменить.'),actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),TextButton(onPressed: () {context.read<AppState>().clearRoomPanorama(widget.room.id);Navigator.pop(ctx);Navigator.pop(context);},child: const Text('Удалить'),),],),);}

@override
Widget build(BuildContext context) {
final c = context.colors;
final panoramaPath = widget.room.panoramaPath;

return Scaffold(
backgroundColor: Colors.black,
appBar: AppBar(
title: Text('Панорама: ${widget.room.name}'),
actions: [
if (panoramaPath != null)
IconButton(
icon: const Icon(Icons.delete_outline),
tooltip: 'Удалить панораму',
onPressed: _deletePanorama,
),
IconButton(
icon: _importing
? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
: const Icon(Icons.add_photo_alternate_outlined),
tooltip: panoramaPath != null ? 'Заменить панораму' : 'Загрузить панораму',
onPressed: _importing ? null : _showSourcePicker,
),
],
),
body: panoramaPath != null
? PanoramaViewer(child: Image.file(File(panoramaPath)))
: Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(Icons.panorama_photosphere_outlined, size: 56, color: c.tertiaryLabel),
const SizedBox(height: 16),
Text(
'Панорама ещё не загружена',
style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
textAlign: TextAlign.center,
),
const SizedBox(height: 8),
Text(
'Снимите панораму штатной камерой телефона (режим «Панорама» есть почти на любом Android) '
'или выберите готовый снимок из галереи.',
style: TextStyle(color: Colors.white70, fontSize: 13),
textAlign: TextAlign.center,
),
const SizedBox(height: 20),
ElevatedButton.icon(
onPressed: _importing ? null : _showSourcePicker,
icon: const Icon(Icons.add_photo_alternate_outlined),
label: Text(_importing ? 'Загрузка...' : 'Загрузить панораму'),
),
],
),
),
),
bottomNavigationBar: _error != null
? Container(
color: Colors.black87,
padding: const EdgeInsets.all(12),
child: Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
)
: null,
);
}
}
