import 'package:kumi_app/app/app.dart';
import 'package:kumi_app/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
