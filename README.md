## Description


## Usage

```dart
import 'dart:html';
import 'package:reactive_keyboard/reactive_keyboard.dart';

void main() {
  var keyboard = new ReactiveKeyboard(query('body'));

  keyboard.keyStream.listen((str) => print(str));
  keyboard.lineStream.listen((str) => print(str));
  keyboard.htmlLineStream.listen((str) => print(str));
  keyboard.navStream.listen((azimuth) => print(azimuth));
  keyboard.hotKeyStream.listen((str) => print(str));

}

```
## HotKeys

How to listen for specific HotKey:

```dart
keyboard.hotKeyStream.where((hk) => hk == 'ctrl+C').listen((str) => print("BREAK!"));
```

## Observable on linestream

How to use observables on lineStream:

```dart
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
```