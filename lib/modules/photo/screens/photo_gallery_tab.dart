// modules/photo/screens/photo_gallery_tab.dart
// 역할: 화분 상세의 "사진" 탭. 3열 그리드(날짜순) + 카메라/갤러리 추가 버튼.
//       사진 탭하면 전체화면 뷰어로 이동. PhotoProvider 를 상위에서 provide + loadFor.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/app_paths.dart';
import '../../../core/theme.dart';
import '../photo_provider.dart';
import 'photo_viewer.dart';

class PhotoGalleryTab extends StatelessWidget {
  final int plantId;
  const PhotoGalleryTab({super.key, required this.plantId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoProvider>();

    return Stack(
      children: [
        if (provider.loading)
          const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
        else if (provider.isEmpty)
          const Center(
            child: Text('아직 사진이 없어요\n아래 버튼으로 추가해 보세요',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: provider.photos.length,
            itemBuilder: (context, i) {
              final photo = provider.photos[i];
              final isMain = photo.id == provider.mainPhotoId;
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PhotoViewer(
                      provider: provider,
                      initialIndex: i,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(AppPaths.abs(photo.filePath)),
                          fit: BoxFit.cover),
                      if (isMain)
                        Positioned(
                          left: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.star,
                                size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'add_photo_$plantId',
            onPressed: () => _pickSource(context, provider),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('사진 추가'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickSource(BuildContext context, PhotoProvider provider) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      await provider.addFromSource(source);
    }
  }
}
