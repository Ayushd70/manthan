import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:manthan/features/rag/domain/document_import.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xml/xml.dart';

/// Extracts plain text from supported document formats for RAG indexing.
class DocumentTextExtractor {
  const DocumentTextExtractor();

  static const _wordNamespace =
      'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

  /// Reads [bytes] based on the [fileName] extension.
  String extract({required String fileName, required List<int> bytes}) {
    switch (p.extension(fileName).toLowerCase()) {
      case '.txt':
      case '.md':
      case '.markdown':
      case '.text':
        return _decodeText(bytes);
      case '.pdf':
        return _extractPdf(bytes);
      case '.docx':
        return _extractDocx(bytes);
      default:
        throw DocumentImportException(
          'Unsupported file type "${p.extension(fileName)}". '
          'Use .txt, .md, .pdf, or .docx.',
        );
    }
  }

  String _decodeText(List<int> bytes) {
    final text = utf8.decode(bytes, allowMalformed: true).trim();
    if (text.isEmpty) {
      throw const DocumentImportException('The file is empty.');
    }
    return text;
  }

  String _extractPdf(List<int> bytes) {
    final document = PdfDocument(inputBytes: Uint8List.fromList(bytes));
    try {
      final text = PdfTextExtractor(document).extractText().trim();
      if (text.isEmpty) {
        throw const DocumentImportException(
          'No selectable text found. This PDF may be scanned or image-only.',
        );
      }
      return text;
    } finally {
      document.dispose();
    }
  }

  String _extractDocx(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final entry = archive.findFile('word/document.xml');
    if (entry == null) {
      throw const DocumentImportException('Invalid DOCX file.');
    }

    final xmlBytes = entry.content;
    final xmlText = utf8.decode(xmlBytes, allowMalformed: true);
    final document = XmlDocument.parse(xmlText);

    final paragraphs = <String>[];
    for (final paragraph in document.findAllElements(
      'p',
      namespaceUri: _wordNamespace,
    )) {
      final text = paragraph
          .findAllElements('t', namespaceUri: _wordNamespace)
          .map((node) => node.innerText)
          .join();
      final trimmed = text.trim();
      if (trimmed.isNotEmpty) {
        paragraphs.add(trimmed);
      }
    }

    final text = paragraphs.join('\n\n').trim();
    if (text.isEmpty) {
      throw const DocumentImportException('The DOCX file contains no text.');
    }
    return text;
  }
}
