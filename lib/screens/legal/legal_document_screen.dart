import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Legal document viewer for Privacy Policy and Terms of Service
class LegalDocumentScreen extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDocumentScreen({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(type.title),
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: _loadDocument(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading ${type.title}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return Markdown(
            data: snapshot.data ?? '',
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              p: const TextStyle(fontSize: 14, height: 1.5),
              listBullet: const TextStyle(fontSize: 14),
            ),
            onTapLink: (text, href, title) {
              // Handle links if needed in the future
              if (href != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Link: $href')),
                );
              }
            },
          );
        },
      ),
    );
  }

  Future<String> _loadDocument() async {
    try {
      return await rootBundle.loadString(type.assetPath);
    } catch (e) {
      throw Exception('Failed to load document: $e');
    }
  }
}

enum LegalDocumentType {
  privacyPolicy('Privacy Policy', 'assets/legal/privacy_policy.md'),
  termsOfService('Terms of Service', 'assets/legal/terms_of_service.md');

  final String title;
  final String assetPath;

  const LegalDocumentType(this.title, this.assetPath);
}
