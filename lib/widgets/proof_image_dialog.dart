import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

/// Opens a zoomable dialog with a Cloudinary proof image.
void showProofImage(BuildContext context, String url) {
  if (url.isEmpty) return;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: InteractiveViewer(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, _) => const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (_, _, _) => const SizedBox(
            height: 220,
            child: Center(child: Text('Image unavailable')),
          ),
        ),
      ),
    ),
  );
}
