import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/network/app_exception.dart';

/// Turns the on-screen floor plan into a PNG or PDF and shares it.
class LayoutExportRepo {
  const LayoutExportRepo();

  /// Renders the widget under [boundaryKey] (a RepaintBoundary) to PNG.
  Future<Uint8List> capturePng(GlobalKey boundaryKey, {double pixelRatio = 3}) async {
    final boundary = boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw const AppException('The plan is not ready to export yet.');
    }
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw const AppException('Could not create the image.');
    return data.buffer.asUint8List();
  }

  /// A one-page A4 PDF with the plan image and optional notes.
  Future<Uint8List> buildPdf({
    required String title,
    required String subtitle,
    required Uint8List planPng,
    List<String> notes = const [],
  }) async {
    final doc = pw.Document(title: title, author: 'Astro Home');
    final image = pw.MemoryImage(planPng);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
            pw.SizedBox(height: 16),
            pw.Expanded(
              child: pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
            ),
            if (notes.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              for (final n in notes.take(8))
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Bullet(text: n, style: const pw.TextStyle(fontSize: 10)),
                ),
            ],
            pw.SizedBox(height: 10),
            pw.Text(
              'Made with Astro Home',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  /// Writes [bytes] to a temporary file and opens the share sheet.
  Future<void> share(
    Uint8List bytes, {
    required String fileName,
    required String mime,
    String? text,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
      final file = File('${dir.path}/$safe');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: mime)],
          text: text,
          subject: text,
        ),
      );
    } catch (e) {
      throw e is AppException ? e : const AppException('Could not share the file.');
    }
  }
}
