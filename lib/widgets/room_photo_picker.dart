import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../core/constants.dart';
import '../services/image_upload_service.dart';

/// Photo grid that picks, compresses, and uploads room images to Cloudinary.
class RoomPhotoPicker extends StatefulWidget {
  const RoomPhotoPicker({
    super.key,
    required this.photos,
    required this.onChanged,
    this.maxPhotos = AppConstants.maxPhotos,
  });

  final List<String> photos;
  final ValueChanged<List<String>> onChanged;
  final int maxPhotos;

  @override
  State<RoomPhotoPicker> createState() => _RoomPhotoPickerState();
}

class _RoomPhotoPickerState extends State<RoomPhotoPicker> {
  final ImageUploadService _service = ImageUploadService();
  bool _uploading = false;
  String? _error;

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await _service.pickAndUpload(source: source);
      if (!mounted) return;
      if (url != null && !widget.photos.contains(url)) {
        widget.onChanged(<String>[...widget.photos, url]);
      }
    } on ImageUploadFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not upload the photo. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removePhoto(int index) {
    final updated = List<String>.of(widget.photos)..removeAt(index);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Add up to ${widget.maxPhotos} photos. The first photo is the cover.',
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            for (var index = 0; index < widget.photos.length; index++)
              _PhotoTile(
                url: widget.photos[index],
                onRemove: _uploading ? null : () => _removePhoto(index),
              ),
            if (widget.photos.length < widget.maxPhotos)
              _AddTile(
                uploading: _uploading,
                onTap: _uploading ? null : _addPhoto,
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'JPG, PNG, WebP, or HEIC. Maximum 5 MB per photo.',
          style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.url, this.onRemove});

  final String url;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 100,
            height: 100,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  Container(color: scheme.surfaceContainerHighest),
              errorWidget: (_, _, _) => Container(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Remove photo',
              iconSize: 17,
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.uploading, this.onTap});

  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: uploading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add photo',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
