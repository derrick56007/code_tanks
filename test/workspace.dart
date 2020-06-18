import 'dart:convert';
import 'dart:io';

void main() {
  // print('derp');
  Process.start('ls', [], runInShell: true).then((Process process) {
    process.stdout
        .transform(utf8.decoder)
        .listen((data) { print(data); });
    // process.stdin.writeln('Hello, world!');
    // process.stdin.writeln('Hello, galaxy!');
    // process.stdin.writeln('Hello, universe!');
  });
  }