// modules/photo/screens/photo_viewer.dart
// 역할: 전체화면 사진 뷰어. 좌우 스와이프(PageView), 대표사진 지정, 삭제.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_paths.dart';
import '../../../core/theme.dart';
import '../photo_provider.dart';

class PhotoViewer extends StatefulWidget {
  final PhotoProvider provider;
  final int initialIndex;
  const PhotoViewer({
    super.key,
    required this.provider,
    required this.initialIndex,
  });

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 삭제로 목록이 바뀔 수 있으므로 provider를 구독
    return ChangeNotifierProvider.value(
      value: widget.provider,
      child: Consumer<PhotoProvider>(
        builder: (context, provider, _) {
          final photos = provider.photos;
          if (photos.isEmpty) {
            // 모두 삭제되면 닫기
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.of(context).maybePop();
            });
            return const Scaffold(
              backgroundColor: Colors.black,
              body: SizedBox.shrink(),
            );
          }
          if (_index >= photos.length) _index = photos.length - 1;
          final current = photos[_index];
          final isMain = current.id == provider.mainPhotoId;

          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(
                DateFormat('yyyy.MM.dd').format(current.takenAt),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              actions: [
                IconButton(
                  tooltip: '대표사진 지정',
                  icon: Icon(isMain ? Icons.star : Icons.star_border,
                      color: isMain ? AppColors.primary : Colors.white),
                  onPressed:
                      isMain ? null : () => provider.setMain(current.id!),
                ),
                IconButton(
                  tooltip: '삭제',
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () => _confirmDelete(context, provider),
                ),
              ],
            ),
            body: PageView.builder(
              controller: _controller,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                return InteractiveViewer(
                  child: Center(
                    child: Image.file(
                      File(AppPaths.abs(photos[i].filePath)),
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, PhotoProvider provider) async {
    final photos = provider.photos;
    if (_index >= photos.length) return;
    final target = photos[_index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('사진 삭제'),
        content: const Text('이 사진을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.delete(target);
    }
  }
}
