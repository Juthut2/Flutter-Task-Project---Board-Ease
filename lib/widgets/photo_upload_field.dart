import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../services/image_upload_service.dart';

/// Single image uploader backed by Cloudinary.
class PhotoUploadField extends StatefulWidget {
  const PhotoUploadField({
    super.key,
    required this.url,
    required this.onChanged,
    this.emptyLabel = 'Upload photo',
    this.helperText = 'JPG, PNG, WebP, or HEIC. Maximum 5 MB.',
  });

  final String? url;
  final ValueChanged<String?> onChanged;
  final String emptyLabel;
  final String helperText;

  @override
  State<PhotoUploadField> createState() => _PhotoUploadFieldState();
}

class _PhotoUploadFieldState extends State<PhotoUploadField> {
  final ImageUploadService _service = ImageUploadService();
  bool _uploading = false;
  String? _error;

  Future<void> _pick() async {
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
      if (url != null) widget.onChanged(url);
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasPhoto = widget.url != null && widget.url!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (hasPhoto)
          Stack(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: double.infinity,
                  height: 190,
                  child: CachedNetworkImage(
                    imageUrl: widget.url!,
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
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Remove photo',
                    onPressed: _uploading ? null : () => widget.onChanged(null),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: _uploading ? null : _pick,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: _uploading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 30,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.emptyLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
            ),
          ),
        if (hasPhoto) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _uploading ? null : _pick,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Replace photo'),
            ),
          ),
        ],
        if (_uploading) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          widget.helperText,
          style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
