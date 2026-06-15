import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';
import 'package:payqure_home/features/ledger/presentation/widgets/zoomable_pdf_pages.dart';

void main() {
  testWidgets('PDF pages support immediate pinch zoom', (tester) async {
    final page = PdfPreviewPageData(
      image: MemoryImage(Uint8List.fromList(_transparentPixel)),
      width: 1,
      height: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ZoomablePdfPages(pages: [page])),
      ),
    );

    final viewer = tester.widget<InteractiveViewer>(
      find.byKey(const ValueKey('pdf-interactive-viewer')),
    );
    expect(viewer.panEnabled, isTrue);
    expect(viewer.scaleEnabled, isTrue);
    expect(viewer.maxScale, 5);
  });
}

const _transparentPixel = <int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1f,
  0x15,
  0xc4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x44,
  0x41,
  0x54,
  0x08,
  0xd7,
  0x63,
  0xf8,
  0xcf,
  0xc0,
  0xf0,
  0x1f,
  0x00,
  0x05,
  0x00,
  0x01,
  0xff,
  0x89,
  0x99,
  0x3d,
  0x1d,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4e,
  0x44,
  0xae,
  0x42,
  0x60,
  0x82,
];
