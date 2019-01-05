#!/usr/bin/env dart
// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This script uses the extract_messages.dart library to find the Intl.message
/// calls in the target dart files and produces ARB format output. See
/// https://code.google.com/p/arb/wiki/ApplicationResourceBundleSpecification
library extract_to_arb;

import 'dart:io';

import 'package:args/args.dart';

import 'package:intl_translation/intl_translation.dart';

main(List<String> args) {
  var outputDir;
  var outputFilename;
  bool suppressWarnings;
  bool warningsAreErrors;
  bool embeddedPlurals;
  bool transformer;
  String locale;

  var parser = new ArgParser();
  parser.addFlag("suppress-warnings",
      defaultsTo: false,
      callback: (x) => suppressWarnings = x,
      help: 'Suppress printing of warnings.');
  parser.addFlag("warnings-are-errors",
      defaultsTo: false,
      callback: (x) => warningsAreErrors = x,
      help: 'Treat all warnings as errors, stop processing ');
  parser.addFlag("embedded-plurals",
      defaultsTo: true,
      callback: (x) => embeddedPlurals = x,
      help: 'Allow plurals and genders to be embedded as part of a larger '
          'string, otherwise they must be at the top level.');
  parser.addFlag("transformer",
      defaultsTo: false,
      callback: (x) => transformer = x,
      help: "Assume that the transformer is in use, so name and args "
          "don't need to be specified for messages.");
  parser.addOption("locale",
      defaultsTo: null,
      callback: (value) => locale = value,
      help: 'Specify the locale set inside the arb file.');
  parser.addOption("output-dir",
      defaultsTo: '.',
      callback: (value) => outputDir = value,
      help: 'Specify the output directory.');
  parser.addOption("output-file",
      defaultsTo: 'intl_messages.arb',
      callback: (value) => outputFilename = value,
      help: 'Specify the output file.');
  parser.parse(args);
  if (args.length == 0) {
    print('Accepts Dart files and produces $outputFilename');
    print('Usage: extract_to_arb [options] [files.dart]');
    print(parser.usage);
    exit(0);
  }

  extractToArb(args,
      outputDir: outputDir,
      outputFilename: outputFilename,
      suppressWarnings: suppressWarnings,
      warningsAreErrors: warningsAreErrors,
      embeddedPlurals: embeddedPlurals,
      transformer: transformer,
      locale: locale);
}
