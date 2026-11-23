import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

/// Swipeable room photo gallery with page dots.
class RoomPhotoGallery extends StatefulWidget {
  const RoomPhotoGallery({super.key, required this.photos});

  final List<String> photos;

  @override
  State<RoomPhotoGallery> createState() => _RoomPhotoGalleryState();
}

class _RoomPhotoGalleryState extends State<RoomPhotoGallery> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant RoomPhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.photos.length <= _index) {
      _index = widget.photos.isEmpty ? 0 : widget.photos.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (widget.photos.isEmpty) {
      return Container(
        height: 210,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.photo_library_outlined,
              size: 38,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'No photos added yet',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 210,
            child: PageView.builder(
              itemCount: widget.photos.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: widget.photos[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, _) =>
                      Container(color: scheme.surfaceContainerHighest),
                  errorWidget: (_, _, _) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.photos.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(widget.photos.length, (index) {
              final active = index == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? scheme.primary : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
