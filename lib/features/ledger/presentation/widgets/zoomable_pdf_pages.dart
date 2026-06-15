import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_spacing.dart';

class ZoomablePdfPages extends StatefulWidget {
  const ZoomablePdfPages({required this.pages, super.key});

  final List<PdfPreviewPageData> pages;

  @override
  State<ZoomablePdfPages> createState() => _ZoomablePdfPagesState();
}

class _ZoomablePdfPagesState extends State<ZoomablePdfPages> {
  static const _zoomScale = 2.5;

  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    setState(() {
      _isZoomed = !_isZoomed;
      _transformationController.value = _isZoomed
          ? Matrix4.diagonal3Values(_zoomScale, _zoomScale, 1)
          : Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = (constraints.maxWidth - AppSpacing.lg * 2)
            .clamp(240.0, 720.0)
            .toDouble();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: _toggleZoom,
          child: InteractiveViewer(
            key: const ValueKey('pdf-interactive-viewer'),
            transformationController: _transformationController,
            constrained: false,
            minScale: 1,
            maxScale: 5,
            boundaryMargin: const EdgeInsets.all(AppSpacing.xl),
            onInteractionEnd: (_) {
              final zoomed =
                  _transformationController.value.getMaxScaleOnAxis() > 1.01;
              if (zoomed != _isZoomed && mounted) {
                setState(() => _isZoomed = zoomed);
              }
            },
            child: SizedBox(
              width: pageWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final page in widget.pages)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AspectRatio(
                          aspectRatio: page.aspectRatio,
                          child: Image(
                            image: page.image,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
