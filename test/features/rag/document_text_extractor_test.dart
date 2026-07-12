import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/features/rag/data/document_text_extractor.dart';
import 'package:manthan/features/rag/domain/document_import.dart';

void main() {
  const extractor = DocumentTextExtractor();

  group('DocumentTextExtractor', () {
    test('decodes plain text files', () {
      final text = extractor.extract(
        fileName: 'notes.txt',
        bytes: utf8.encode('Hello from a text file.'),
      );
      expect(text, 'Hello from a text file.');
    });

    test('throws for empty text files', () {
      expect(
        () => extractor.extract(fileName: 'empty.md', bytes: <int>[]),
        throwsA(isA<DocumentImportException>()),
      );
    });

    test('extracts text from a minimal DOCX', () {
      final bytes = _minimalDocx('Quarterly revenue grew 12%.');
      final text = extractor.extract(fileName: 'report.docx', bytes: bytes);
      expect(text, contains('Quarterly revenue grew 12%'));
    });

    test('rejects unsupported extensions', () {
      expect(
        () => extractor.extract(fileName: 'sheet.xlsx', bytes: <int>[1, 2, 3]),
        throwsA(
          isA<DocumentImportException>().having(
            (e) => e.message,
            'message',
            contains('Unsupported'),
          ),
        ),
      );
    });
  });
}

List<int> _minimalDocx(String paragraph) {
  final documentXml =
      '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:r><w:t>$paragraph</w:t></w:r></w:p>
  </w:body>
</w:document>''';
  final bytes = utf8.encode(documentXml);
  final archive = Archive()
    ..addFile(ArchiveFile('word/document.xml', bytes.length, bytes));
  return ZipEncoder().encode(archive);
}
