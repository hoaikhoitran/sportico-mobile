import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:group_prj/app/app.dart';

void main() {
  testWidgets('app boots to splash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SporticoApp()));
    expect(find.text('Sportico'), findsOneWidget);
  });
}
