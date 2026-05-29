import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/theme/app_theme.dart';
import 'progress_photo_service.dart';

/// Shows the full photo gallery as a bottom sheet tab inside Progress screen.
class ProgressPhotosSection extends ConsumerWidget {
  const ProgressPhotosSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(progressPhotoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Progress Photos',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            GestureDetector(
              onTap: () => _showAddOptions(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text('Add',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (photos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Icon(Icons.photo_library_outlined,
                    color: AppColors.textMuted, size: 36),
                const SizedBox(height: 8),
                Text('No photos yet',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Track your transformation visually',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          )
        else ...[
          // Grid of photos
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: photos.length,
            itemBuilder: (context, i) => _PhotoThumbnail(
              photo: photos[i],
              allPhotos: photos,
              index: i,
            ),
          ),
          const SizedBox(height: 12),
          if (photos.length >= 2)
            GestureDetector(
              onTap: () => _showComparison(context, photos),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.compare, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text('Before / After Comparison',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  void _showAddOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddPhotoSheet(ref: ref),
    );
  }

  void _showComparison(BuildContext context, List<ProgressPhoto> photos) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ComparisonSheet(photos: photos),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final ProgressPhoto photo;
  final List<ProgressPhoto> allPhotos;
  final int index;

  const _PhotoThumbnail({
    required this.photo,
    required this.allPhotos,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFull(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(photo.localPath), fit: BoxFit.cover),
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  photo.angle[0].toUpperCase() + photo.angle.substring(1),
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFull(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullPhotoViewer(photos: allPhotos, initial: index),
      ),
    );
  }
}

class _FullPhotoViewer extends ConsumerWidget {
  final List<ProgressPhoto> photos;
  final int initial;

  const _FullPhotoViewer({required this.photos, required this.initial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: () async {
              final photo = photos[initial];
              await ref.read(progressPhotoProvider.notifier).deletePhoto(photo.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: photos.length,
        itemBuilder: (_, i) {
          final p = photos[i];
          return Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  child: Image.file(
                    File(p.localPath),
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '${p.angle[0].toUpperCase()}${p.angle.substring(1)} — ${_fmt(p.takenAt)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    if (p.note != null) ...[
                      const SizedBox(height: 4),
                      Text(p.note!,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
}

class _AddPhotoSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddPhotoSheet({required this.ref});

  @override
  State<_AddPhotoSheet> createState() => _AddPhotoSheetState();
}

class _AddPhotoSheetState extends State<_AddPhotoSheet> {
  String _angle = 'front';
  final _noteCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _loading = true);
    try {
      await widget.ref.read(progressPhotoProvider.notifier).addPhoto(
            source: source,
            angle: _angle,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Add Progress Photo',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          // Angle selector
          Text('Angle',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: ['front', 'side', 'back'].map((a) {
              final sel = a == _angle;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _angle = a),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary.withOpacity(0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? AppColors.primary : AppColors.cardBorder),
                    ),
                    child: Text(
                      a[0].toUpperCase() + a.substring(1),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: sel ? AppColors.primary : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            maxLines: 1,
          ),
          const SizedBox(height: 24),
          if (_loading)
            Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    onPressed: () => _pick(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    onPressed: () => _pick(ImageSource.camera),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ComparisonSheet extends StatefulWidget {
  final List<ProgressPhoto> photos;
  const _ComparisonSheet({required this.photos});

  @override
  State<_ComparisonSheet> createState() => _ComparisonSheetState();
}

class _ComparisonSheetState extends State<_ComparisonSheet> {
  int _beforeIdx = 0;
  int _afterIdx = 1;

  @override
  void initState() {
    super.initState();
    // Default: oldest as "before", most recent as "after"
    _beforeIdx = widget.photos.length - 1;
    _afterIdx = 0;
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Before / After',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                // Side by side photos
                Row(
                  children: [
                    Expanded(
                      child: _ComparisonColumn(
                        label: 'Before',
                        photo: photos[_beforeIdx],
                        photoCount: photos.length,
                        selectedIndex: _beforeIdx,
                        onIndexChanged: (i) => setState(() => _beforeIdx = i),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ComparisonColumn(
                        label: 'After',
                        photo: photos[_afterIdx],
                        photoCount: photos.length,
                        selectedIndex: _afterIdx,
                        onIndexChanged: (i) => setState(() => _afterIdx = i),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonColumn extends StatelessWidget {
  final String label;
  final ProgressPhoto photo;
  final int photoCount;
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const _ComparisonColumn({
    required this.label,
    required this.photo,
    required this.photoCount,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: label == 'Before'
                ? AppColors.error.withOpacity(0.15)
                : AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: label == 'Before' ? AppColors.error : AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(photo.localPath),
            fit: BoxFit.cover,
            height: 280,
            width: double.infinity,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _fmt(photo.takenAt),
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 8),
        // Photo selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            photoCount,
            (i) => GestureDetector(
              onTap: () => onIndexChanged(i),
              child: Container(
                width: i == selectedIndex ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i == selectedIndex
                      ? AppColors.primary
                      : AppColors.textMuted,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
}
