import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const lessonIds = ['equal-parts', 'unit-fractions', 'equal-sharing'];
final lessonProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  if (!lessonIds.contains(id)) throw ArgumentError('Unknown lesson');
  return jsonDecode(await rootBundle.loadString('assets/lessons/$id.json')) as Map<String, dynamic>;
});
final router = GoRouter(routes: [
  GoRoute(path: '/', builder: (_, state) => const LibraryScreen()),
  GoRoute(path: '/lesson/:id', builder: (_, state) => LessonScreen(id: state.pathParameters['id']!)),
]);
void main() => runApp(const ProviderScope(child: TutorApp()));

class TutorApp extends StatelessWidget {
  const TutorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: router,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff234c68)), useMaterial3: true),
  );
}

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('نموذج تعليمي تجريبي')),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      const Text('رياضيات الصف الرابع', style: TextStyle(fontSize: 24)),
      const Text('محتوى تجريبي بانتظار مراجعة تربوية. المساعد المباشر غير متصل.'),
      const SizedBox(height: 24),
      for (final id in lessonIds) ref.watch(lessonProvider(id)).when(
        data: (lesson) => Card(child: ListTile(
          minVerticalPadding: 20,
          title: Text(lesson['title'] as String),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => context.go('/lesson/$id'),
        )),
        loading: () => const LinearProgressIndicator(),
        error: (_, stack) => const Text('تعذر تحميل الدرس. حاول مجدداً.'),
      ),
    ]),
  );
}

class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(leading: IconButton(tooltip: 'العودة إلى الدروس', icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')), title: const Text('الدرس')),
    body: ref.watch(lessonProvider(id)).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, stack) => const Center(child: Text('تعذر تحميل الدرس')),
      data: (lesson) => ListView(padding: const EdgeInsets.all(24), children: [
        Text(lesson['title'] as String, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        for (final block in lesson['blocks'] as List) Padding(
          padding: const EdgeInsets.only(bottom: 24), child: Text(block['text'] as String, style: const TextStyle(fontSize: 22)),
        ),
        if (id != 'equal-sharing') ...[
          const FractionBar(numerator: 1, denominator: 2),
          const SizedBox(height: 24),
          const FractionBar(numerator: 1, denominator: 4),
        ],
        const SizedBox(height: 24),
        const Text('المساعد الصوتي والنصي المباشر غير متاح بعد. هذه الرسوم أمثلة من الدرس وليست إجابات مولدة بالذكاء الاصطناعي.'),
      ]),
    ),
  );
}

class FractionBar extends StatelessWidget {
  const FractionBar({super.key, required this.numerator, required this.denominator})
      : assert(denominator > 0 && denominator <= 12), assert(numerator >= 0 && numerator <= denominator);
  final int numerator;
  final int denominator;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$numerator من $denominator أجزاء متساوية من الكل نفسه',
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ExcludeSemantics(child: Directionality(textDirection: TextDirection.ltr, child: Text('$numerator/$denominator'))),
      ExcludeSemantics(child: SizedBox(height: 64, width: double.infinity,
        child: CustomPaint(painter: _BarPainter(numerator, denominator)))),
    ]),
  );
}
class _BarPainter extends CustomPainter {
  _BarPainter(this.numerator, this.denominator);
  final int numerator;
  final int denominator;
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / denominator;
    final fill = Paint()..color = const Color(0xff234c68);
    final border = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2;
    for (var i = 0; i < denominator; i++) {
      final rect = Rect.fromLTWH(i * cell + 1, 1, cell - 2, size.height - 2);
      if (i < numerator) canvas.drawRect(rect, fill);
      canvas.drawRect(rect, border);
    }
  }
  @override
  bool shouldRepaint(_BarPainter old) => old.numerator != numerator || old.denominator != denominator;
}
