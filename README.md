## Description


## Usage

The Factory constructor for making a new ReactiveKeyboard object

Takes a target element to observe keyboard events from and some named
parameters to aid in the configuration of the ReactiveKeyboard. Optional
named argmuments are as follows:
* allowShiftOnlyHotKeys = `false`: Whether or not to capture shift only
  hot key modifiers--excludes _shift_+`_SPECIAL_KEYS`
* allowAltKeyPress = `false`: Whether or not to allow _alt_ key presses
  through the `keyStream`
* allowEnterKeyPress = `false`: Whether or not to include the enter key
  as part of the line for the `lineStream`
* navKeys = `NUM_NAV`: A map of keys to filter for in the `navStream`
* delKeys = `DEFAULT_DEL_KEYS`

```dart
import 'dart:html';
import 'package:reactive_keyboard/reactive_keyboard.dart';

void main() {
  var keyboard = new ReactiveKeyboard(querySelector('body'));

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
