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

import 'package:path/path.dart' as path;

import 'package:intl_translation/extract_messages.dart';
import 'package:intl_translation/generate_localized.dart';
import 'package:intl_translation/src/intl_message.dart';
import 'package:intl_translation/src/icu_parser.dart';

/// Keeps track of all the messages we have processed so far, keyed by message
/// name.
Map<String, List<MainMessage>> messages;

const jsonDecoder = const JsonCodec();

generateFromArb(
    List<String> messageFilePaths, List<String> translationFilePaths,
    {bool useJson: false,
    bool suppressWarnings: false,
    String outputDir: '.',
    String generatedFilePrefix: '',
    bool useDeferredLoading: true,
    String codegenMode: 'debug',
    bool transformer: false}) {
  var generation =
      (useJson ? new JsonMessageGeneration() : new MessageGeneration())
        ..generatedFilePrefix = generatedFilePrefix
        ..useDeferredLoading = useDeferredLoading
        ..codegenMode = codegenMode;
  var extraction = new MessageExtraction()..suppressWarnings = suppressWarnings;

  // TODO(alanknight): There is a possible regression here. If a project is
  // using the transformer and expecting it to provide names for messages with
  // parameters, we may report those names as missing. We now have two distinct
  // mechanisms for providing names: the transformer and just using the message
  // text if there are no parameters. Previously this was always acting as if
  // the transformer was in use, but that breaks the case of using the message
  // text. The intent is to deprecate the transformer, but if this is an issue
  // for real projects we could provide a command-line flag to indicate which
  // sort of automated name we're using.
  extraction.suppressWarnings = true;
  var allMessages = messageFilePaths
      .map((each) => extraction.parseFile(new File(each), transformer));

  messages = new Map();
  for (var eachMap in allMessages) {
    eachMap.forEach(
        (key, value) => messages.putIfAbsent(key, () => []).add(value));
  }
  for (var translationFilePath in translationFilePaths) {
    var file = new File(translationFilePath);
    generateLocaleFile(file, outputDir, generation);
  }

  var mainImportFile = new File(path.join(
      outputDir, '${generation.generatedFilePrefix}messages_all.dart'));
  mainImportFile.writeAsStringSync(generation.generateMainImportFile());
}

/// Create the file of generated code for a particular locale. We read the ARB
/// data and create [BasicTranslatedMessage] instances from everything,
/// excluding only the special _locale attribute that we use to indicate the
/// locale. If that attribute is missing, we try to get the locale from the last
/// section of the file name.
void generateLocaleFile(
    File file, String targetDir, MessageGeneration generation) {
  var src = file.readAsStringSync();
  var data = jsonDecoder.decode(src);
  var locale = data["@@locale"] ?? data["_locale"];
  if (locale == null) {
    // Get the locale from the end of the file name. This assumes that the file
    // name doesn't contain any underscores except to begin the language tag
    // and to separate language from country. Otherwise we can't tell if
    // my_file_fr.arb is locale "fr" or "file_fr".
    var name = path.basenameWithoutExtension(file.path);
    locale = name.split("_").skip(1).join("_");
    print("No @@locale or _locale field found in $name, "
        "assuming '$locale' based on the file name.");
  }
  generation.allLocales.add(locale);

  List<TranslatedMessage> translations = [];
  data.forEach((id, messageData) {
    TranslatedMessage message = recreateIntlObjects(id, messageData);
    if (message != null) {
      translations.add(message);
    }
  });
  generation.generateIndividualMessageFile(locale, translations, targetDir);
}

/// Regenerate the original IntlMessage objects from the given [data]. For
/// things that are messages, we expect [id] not to start with "@" and
/// [data] to be a String. For metadata we expect [id] to start with "@"
/// and [data] to be a Map or null. For metadata we return null.
BasicTranslatedMessage recreateIntlObjects(String id, data) {
  if (id.startsWith("@")) return null;
  if (data == null) return null;
  var parsed = pluralAndGenderParser.parse(data).value;
  if (parsed is LiteralString && parsed.string.isEmpty) {
    parsed = plainParser.parse(data).value;
  }
  return new BasicTranslatedMessage(id, parsed);
}

/// A TranslatedMessage that just uses the name as the id and knows how to look
/// up its original messages in our [messages].
class BasicTranslatedMessage extends TranslatedMessage {
  BasicTranslatedMessage(String name, translated) : super(name, translated);

  List<MainMessage> get originalMessages => (super.originalMessages == null)
      ? _findOriginals()
      : super.originalMessages;

  // We know that our [id] is the name of the message, which is used as the
  //key in [messages].
  List<MainMessage> _findOriginals() => originalMessages = messages[id];
}

final pluralAndGenderParser = new IcuParser().message;
final plainParser = new IcuParser().nonIcuMessage;
