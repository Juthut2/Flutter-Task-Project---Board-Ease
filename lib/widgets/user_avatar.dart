import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../core/helpers.dart';

/// Circular profile photo with an initials fallback.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 20,
    this.onTap,
    this.busy = false,
    this.showEditBadge = false,
  });

  final String name;
  final String? photoUrl;
  final double radius;
  final VoidCallback? onTap;
  final bool busy;
  final bool showEditBadge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = radius * 2;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    final initials = CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        AppHelpers.initials(name),
        style: TextStyle(
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );

    Widget avatar = hasPhoto
        ? ClipOval(
            child: SizedBox(
              width: size,
              height: size,
              child: CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => initials,
                errorWidget: (_, _, _) => initials,
              ),
            ),
          )
        : initials;

    if (busy) {
      avatar = Stack(
        children: <Widget>[
          avatar,
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (showEditBadge) {
      avatar = Stack(
        children: <Widget>[
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: radius * 0.34,
              backgroundColor: scheme.primary,
              child: Icon(
                Icons.camera_alt_rounded,
                size: radius * 0.34,
                color: scheme.onPrimary,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap == null) return avatar;
    return InkWell(
      onTap: busy ? null : onTap,
      customBorder: const CircleBorder(),
      child: avatar,
    );
  }
}
