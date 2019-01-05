#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A main program that imitates the action of the transformer, adding
/// name and args parameters to Intl.message calls automatically.
///
/// This is mainly intended to test the transformer logic outside of barback.
/// It takes as input a single source Dart file and rewrites any
/// Intl.message or related calls to automatically include the name and args
/// parameters and writes the result to stdout.
///
import 'dart:io';

import 'package:args/args.dart';

import 'package:intl_translation/src/message_rewriter.dart';
import 'package:dart_style/dart_style.dart';

String outputFileOption = 'transformed_output.dart';

bool useStringSubstitution = true;
bool replace = false;
bool forceRewrite = false;

rewriteIntlMessages(List<String> filePaths,
    {String outputFileOption: 'transformed_output.dart',
    bool replace: false,
    bool forceRewrite: false,
    bool useStringSubstitution: true}) {
  var formatter = new DartFormatter();
  for (var inputFile in filePaths) {
    var outputFile = replace ? inputFile : outputFileOption;
    var file = new File(inputFile);
    var content = file.readAsStringSync();
    var newSource = rewriteMessages(content, '$file',
        forceRewrite: forceRewrite,
        useStringSubstitution: useStringSubstitution);
    if (content == newSource) {
      print('No changes to $outputFile');
    } else {
      print('Writing new source to $outputFile');
      var out = new File(outputFile);
      out.writeAsStringSync(formatter.format(newSource));
    }
  }
}
