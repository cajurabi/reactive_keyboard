import 'dart:html';
import 'package:reactive_keyboard/reactive_keyboard.dart';

void main() {
  var keyboard = new ReactiveKeyboard(querySelector('body'));

//  var keyboard = document.body.onKeyDown.listen((value) {
//    print("Received: $value");
//  });

//  keyboard.rawKeyCombinedStream.listen((key) {
//    print("Type: ${key.type}");
//    print("Keycode: ${key.keyCode}");
//    print("altKey: ${key.altKey}");
//    print("shiftKey: ${key.shiftKey}");
//  });

//  keyboard.keyStream.listen((str) => print(str));
//  keyboard.lineStream.listen((str) => print(str));
//  keyboard.htmlLineStream.listen((str) => print(str));
  keyboard.navStream.listen((azimuth) => print(azimuth));
  keyboard.hotKeyStream.listen((str) => print(str));

//  keyboard.htmlKeyStream.listen((str) => print(str));

  keyboard.changes.listen((records) {
    for (var record in records) {
      if (record.name == new Symbol('htmlLineBuffer')) {
        print(record.newValue);
      }
    }
  });

  keyboard.changes.listen((records) {
    for (var record in records) {
      if (record.name == new Symbol('lineBuffer')) {
        print(record.newValue);
      }
    }
  });

}
