import 'package:kumi_note/app/app.dart';
import 'package:kumi_note/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
