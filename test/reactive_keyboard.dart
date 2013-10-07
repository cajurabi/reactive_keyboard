import 'dart:html';
import 'package:reactive_keyboard/reactive_keyboard.dart';

void main() {
  var keyboard = new ReactiveKeyboard(query('body'));

//  keyboard.keyStream.listen((str) => print(str));
//  keyboard.lineStream.listen((str) => print(str));
  keyboard.htmlLineStream.listen((str) => print(str));
//  keyboard.navStream.listen((azimuth) => print(azimuth));
  keyboard.hotKeyStream.listen((str) => print(str));
//  keyboard.htmlKeyStream.listen((str) => print(str));

//  keyboard.changes.listen((records) {
//    for (var record in records) {
//      if (record.changes(new Symbol('htmlLineBuffer'))) {
//        print(keyboard.htmlLineBuffer);
//      }
//    }
//  });

}
