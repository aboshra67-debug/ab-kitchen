import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhotoCreditsScreen extends StatelessWidget {
  const PhotoCreditsScreen({super.key});
  Future<List<Map<String, dynamic>>> _credits() async {
    final input = await rootBundle.loadString('assets/data/licensed_photo_credits.json');
    return (jsonDecode(input) as List<dynamic>).cast<Map<String, dynamic>>();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('مصادر الصور وحقوقها')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _credits(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(children: [
          const Padding(padding: EdgeInsets.all(16), child: Text(
            'صور طعام فوتوغرافية من Wikimedia Commons. الأسماء، والتراخيص، وروابط الملفات الأصلية مسجلة أدناه. بعض الصور حُوّلت إلى WebP لتقليل الحجم؛ تظل حقوق المصورين محفوظة. اضغط على المصدر لنسخ بياناته.',
          )),
          for (final credit in snap.data!)
            Card(child: ListTile(
              title: Text(credit['filename'] as String),
              subtitle: Text('${credit['author']} • ${credit['license']}'),
              trailing: const Icon(Icons.copy_outlined),
              onTap: () async {
                final text = '${credit['filename']}\nPhotographer: ${credit['author']}\nLicense: ${credit['license']}\nSource: ${credit['source_file_page']}\nModified: resize/re-encode to WebP';
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ اسم المصور والترخيص ورابط الصورة')));
                }
              },
            )),
        ]);
      },
    ),
  );
}