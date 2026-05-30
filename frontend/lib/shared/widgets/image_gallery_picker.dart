import 'dart:io';
import 'package:flutter/material.dart';

class GalleryImageItem {
  final File? file;
  final String? url;

  const GalleryImageItem._({this.file, this.url});

  factory GalleryImageItem.file(File f) => GalleryImageItem._(file: f);
  factory GalleryImageItem.url(String u) => GalleryImageItem._(url: u);

  bool get isNetwork => url != null;
  bool get isLocal => file != null;
}

class ImageGalleryPicker extends StatelessWidget {
  final List<GalleryImageItem> images;
  final VoidCallback? onAdd;
  final void Function(int index)? onRemove;
  final bool Function(int index)? canRemove;
  final void Function(int index)? onTapImage;
  final bool showAddButton;
  final double itemSize;
  final double borderRadius;
  final Axis axis;
  final int crossAxisCount;

  const ImageGalleryPicker({
    super.key,
    required this.images,
    this.onAdd,
    this.onRemove,
    this.canRemove,
    this.onTapImage,
    this.showAddButton = true,
    this.itemSize = 80,
    this.borderRadius = 8,
    this.axis = Axis.horizontal,
    this.crossAxisCount = 3,
  });

  bool _shouldShowRemove(int index) {
    if (onRemove == null) return false;
    if (canRemove == null) return true;
    return canRemove!(index);
  }

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.horizontal) {
      return SizedBox(
        height: itemSize,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: images.length + (showAddButton ? 1 : 0),
          itemBuilder: (context, index) {
            if (showAddButton && index == 0) {
              return _AddButton(size: itemSize, borderRadius: borderRadius, onTap: onAdd);
            }
            final imageIndex = showAddButton ? index - 1 : index;
            return _GalleryThumbnail(
              item: images[imageIndex],
              size: itemSize,
              borderRadius: borderRadius,
              margin: const EdgeInsets.only(right: 12),
              onRemove: _shouldShowRemove(imageIndex) ? () => onRemove!(imageIndex) : null,
              onTap: onTapImage != null ? () => onTapImage!(imageIndex) : null,
            );
          },
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return _GalleryThumbnail(
          item: images[index],
          size: itemSize,
          borderRadius: borderRadius,
          margin: EdgeInsets.zero,
          onRemove: _shouldShowRemove(index) ? () => onRemove!(index) : null,
          onTap: onTapImage != null ? () => onTapImage!(index) : null,
        );
      },
    );
  }
}

class _AddButton extends StatelessWidget {
  final double size;
  final double borderRadius;
  final VoidCallback? onTap;

  const _AddButton({required this.size, required this.borderRadius, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: const Color(0xFF4F46E5).withOpacity(0.5),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: Color(0xFF4F46E5)),
            SizedBox(height: 2),
            Text("Añadir", style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _GalleryThumbnail extends StatelessWidget {
  final GalleryImageItem item;
  final double size;
  final double borderRadius;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const _GalleryThumbnail({
    required this.item,
    required this.size,
    required this.borderRadius,
    this.margin = const EdgeInsets.only(right: 12),
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnail = Container(
      width: size,
      height: size,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: item.isNetwork
            ? Image.network(
                item.url!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stack) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              )
            : Image.file(item.file!, fit: BoxFit.cover),
      ),
    );

    return Stack(
      children: [
        if (onTap != null)
          GestureDetector(onTap: onTap, child: thumbnail)
        else
          thumbnail,
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 16,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
