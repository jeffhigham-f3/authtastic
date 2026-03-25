import 'dart:async';

import 'package:flutter/services.dart';

const _clearDelay = Duration(seconds: 30);

void copyAndScheduleClear(String value) {
  Clipboard.setData(ClipboardData(text: value));
  Timer(_clearDelay, () {
    Clipboard.setData(const ClipboardData(text: ''));
  });
}
