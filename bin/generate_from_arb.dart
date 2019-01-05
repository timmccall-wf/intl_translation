#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A main program that takes as input a source Dart file and a number
/// of ARB files representing translations of messages from the corresponding
/// Dart file. See extract_to_arb.dart and make_hardcoded_translation.dart.
///
/// If the ARB file has an @@locale or _locale value, that will be used as
/// the locale. If not, we will try to figure out the locale from the end of
/// the file name, e.g. foo_en_GB.arb will be assumed to be in en_GB locale.
///
/// This produces a series of files named
/// "messages_<locale>.dart" containing messages for a particular locale
/// and a main import file named "messages_all.dart" which has imports all of
/// them and provides an initializeMessages function.

library generate_from_arb;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:intl_translation/intl_translation.dart';

import 'package:intl_translation/src/intl_message.dart';

/// Keeps track of all the messages we have processed so far, keyed by message
/// name.
Map<String, List<MainMessage>> messages;

const jsonDecoder = const JsonCodec();

main(List<String> args) {
  var outputDir;
  bool useJson;
  bool suppressWarnings;
  bool generatedFilePrefix;
  bool useDeferredLoading;
  String codegenMode;
  bool transformer;

  var parser = new ArgParser();
  parser.addFlag('json',
      defaultsTo: false,
      callback: (x) => useJson = x,
      help: 'Generate translations as a JSON string rather than as functions.');
  parser.addFlag("suppress-warnings",
      defaultsTo: false,
      callback: (x) => suppressWarnings = x,
      help: 'Suppress printing of warnings.');
  parser.addOption('output-dir',
      defaultsTo: '.',
      callback: (x) => outputDir = x,
      help: 'Specify the output directory.');
  parser.addOption("generated-file-prefix",
      defaultsTo: '',
      callback: (x) => generatedFilePrefix = x,
      help: 'Specify a prefix to be used for the generated file names.');
  parser.addFlag("use-deferred-loading",
      defaultsTo: true,
      callback: (x) => useDeferredLoading = x,
      help: 'Generate message code that must be loaded with deferred loading. '
          'Otherwise, all messages are eagerly loaded.');
  parser.addOption('codegen_mode',
      allowed: ['release', 'debug'],
      defaultsTo: 'debug',
      callback: (x) => codegenMode = x,
      help: 'What mode to run the code generator in. Either release or debug.');
  parser.addFlag("transformer",
      defaultsTo: false,
      callback: (x) => transformer = x,
      help: "Assume that the transformer is in use, so name and args "
          "don't need to be specified for messages.");

  parser.parse(args);
  var dartFiles = args.where((x) => x.endsWith("dart")).toList();
  var jsonFiles = args.where((x) => x.endsWith(".arb")).toList();
  if (dartFiles.length == 0 || jsonFiles.length == 0) {
    print('Usage: generate_from_arb [options]'
        ' file1.dart file2.dart ...'
        ' translation1_<languageTag>.arb translation2.arb ...');
    print(parser.usage);
    exit(0);
  }

  generate_from_arb(dartFiles, jsonFiles,
      outputDir: outputDir,
      useJson: useJson,
      suppressWarnings: suppressWarnings,
      generatedFilePrefix: generatedFilePrefix,
      useDeferredLoading: useDeferredLoading,
      codegenMode: codegenMode,
      transformer: transformer);
}
