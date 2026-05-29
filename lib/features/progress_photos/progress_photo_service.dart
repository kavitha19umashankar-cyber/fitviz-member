import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

const _keyPhotos = 'progress_photos';

class ProgressPhoto {
  final String id;
  final String localPath;
  final DateTime takenAt;
  final String? note;
  final String angle; // 'front', 'side', 'back'

  const ProgressPhoto({
    required this.id,
    required this.localPath,
    required this.takenAt,
    this.note,
    this.angle = 'front',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'localPath': localPath,
        'takenAt': takenAt.toIso8601String(),
        'note': note,
        'angle': angle,
      };

  factory ProgressPhoto.fromJson(Map<String, dynamic> j) => ProgressPhoto(
        id: j['id'] as String,
        localPath: j['localPath'] as String,
        takenAt: DateTime.parse(j['takenAt'] as String),
        note: j['note'] as String?,
        angle: j['angle'] as String? ?? 'front',
      );
}

class ProgressPhotoNotifier extends Notifier<List<ProgressPhoto>> {
  @override
  List<ProgressPhoto> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPhotos);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => ProgressPhoto.fromJson(e as Map<String, dynamic>))
          .where((p) => File(p.localPath).existsSync())
          .toList();
      state = list;
    } catch (_) {}
  }

  Future<ProgressPhoto?> addPhoto({
    required ImageSource source,
    required String angle,
    String? note,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return null;

    // Compress and save to app documents
    final dir = await getApplicationDocumentsDirectory();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final destPath = '${dir.path}/progress_$id.jpg';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      destPath,
      quality: 80,
    );
    final finalPath = compressed?.path ?? picked.path;

    final photo = ProgressPhoto(
      id: id,
      localPath: finalPath,
      takenAt: DateTime.now(),
      note: note,
      angle: angle,
    );

    final updated = [photo, ...state];
    state = updated;
    await _persist(updated);
    return photo;
  }

  Future<void> deletePhoto(String id) async {
    final photo = state.firstWhere((p) => p.id == id, orElse: () => state.first);
    try {
      await File(photo.localPath).delete();
    } catch (_) {}
    final updated = state.where((p) => p.id != id).toList();
    state = updated;
    await _persist(updated);
  }

  Future<void> _persist(List<ProgressPhoto> photos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyPhotos, jsonEncode(photos.map((p) => p.toJson()).toList()));
  }
}

final progressPhotoProvider =
    NotifierProvider<ProgressPhotoNotifier, List<ProgressPhoto>>(
        ProgressPhotoNotifier.new);
