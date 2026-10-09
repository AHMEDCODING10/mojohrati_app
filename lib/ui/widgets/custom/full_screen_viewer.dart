import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../config/colors.dart';

class ProductGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String heroTag;

  const ProductGalleryViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.heroTag,
  });

  @override
  State<ProductGalleryViewer> createState() => _ProductGalleryViewerState();
}

class _ProductGalleryViewerState extends State<ProductGalleryViewer> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(widget.images[index]),
                initialScale: PhotoViewComputedScale.contained,
                heroAttributes: PhotoViewHeroAttributes(tag: '${widget.heroTag}_$index'),
              );
            },
            itemCount: widget.images.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold),
            ),
            pageController: PageController(initialPage: widget.initialIndex),
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
          ),
          // Close Button
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Page Indicator
          if (widget.images.length > 1)
            Positioned(
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
