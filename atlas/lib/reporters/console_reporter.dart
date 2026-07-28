import 'package:atlas/repository_stats.dart';

class ConsoleReporter {
  void printSummary(RepositoryStats stats) {
    print('');
    print('Repository scan complete');
    print('------------------------');
    print('Directories : ${stats.directories}');
    print('Dart files  : ${stats.dartFiles}');
    print('Test files  : ${stats.testFiles}');
    print('Pubspec     : ${stats.pubspecFiles > 0 ? "✓" : "✗"}');
    print('');
  }
}