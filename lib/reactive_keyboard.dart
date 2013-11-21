library reactive_keyboard;

import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'package:observe/observe.dart';

import 'package:stream_ext/stream_ext.dart';
//import 'package:merge_all/merge_all.dart';


class ReactiveKeyboard extends Observable with ChangeNotifier {
  final Element _target;
  final Stream<KeyboardEvent> rawKeyCombinedStream;
  final Stream<KeyboardEvent> rawKeyUpStream;
  final Stream<KeyboardEvent> rawKeyDownStream;
  final Stream<KeyboardEvent> rawKeyPressStream;

  bool allowShiftOnlyHotKeys;
  bool allowAltKeyPress;
  bool allowEnterKeyPress;
  Map<KeyCode, int> navKeys;
  List<int> delKeys;

  String _lineBuffer = '';
  String _htmlLineBuffer = '';

  Map<String, Stream> _streamMemos = {};

  // DOM event types consts
  static const String KEY_PRESS = 'keypress';
  static const String KEY_UP    = 'keyup';
  static const String KEY_DOWN  = 'keydown';

  // Azimuth nav consts
  static const int N  = 0;
  static const int NE = 45;
  static const int E  = 90;
  static const int SE = 135;
  static const int S  = 180;
  static const int SW = 225;
  static const int W  = 270;
  static const int NW = 315;

  static const List<int> DEFAULT_DEL_KEYS = const [KeyCode.DELETE, KeyCode.BACKSPACE, KeyCode.NUM_DELETE];

  static const Map<int, int> NUM_NAV = const {
    KeyCode.NUM_NORTH      : N,
    KeyCode.NUM_NORTH_EAST : NE,
    KeyCode.NUM_EAST       : E,
    KeyCode.NUM_SOUTH_EAST : SE,
    KeyCode.NUM_SOUTH      : S,
    KeyCode.NUM_SOUTH_WEST : SW,
    KeyCode.NUM_WEST       : W,
    KeyCode.NUM_NORTH_WEST : NW
  };

  static const Map<int, int> ARROW_NAV = const {
    KeyCode.UP             : N,
    KeyCode.LEFT           : W,
    KeyCode.DOWN           : S,
    KeyCode.RIGHT          : E
  };

  // Load Runner Nav
  static const Map<int, int> IJKL_NAV = const {
    KeyCode.I             : N,
    KeyCode.J             : W,
    KeyCode.K             : S,
    KeyCode.L             : E
  };

  // VI Nav
  static const Map<int, int> HJKL_NAV = const {
    KeyCode.K             : N,
    KeyCode.H             : W,
    KeyCode.J             : S,
    KeyCode.L             : E
  };

  // DOOM/QUAKE Nav
  static const Map<int, int> WASD_NAV = const {
    KeyCode.W             : N,
    KeyCode.A             : W,
    KeyCode.S             : S,
    KeyCode.D             : E
  };

  static const List<int> _ENTER_KEYS = const [KeyCode.ENTER, KeyCode.MAC_ENTER];

  static const Map<int, String> _COMBO_KEYS = const {
    KeyCode.OPEN_SQUARE_BRACKET: '[',
    KeyCode.CLOSE_SQUARE_BRACKET: ']',
    KeyCode.COMMA: ',',
    KeyCode.SEMICOLON: ';',
    KeyCode.BACKSLASH: '\\',
    KeyCode.SLASH: '/',
    KeyCode.DASH: '-',
    KeyCode.APOSTROPHE: "`",
    KeyCode.EQUALS: '=',
    KeyCode.FF_EQUALS: '=',
    KeyCode.FF_SEMICOLON: ';',
    KeyCode.PERIOD: '.',
    KeyCode.QUESTION_MARK: '?',
    KeyCode.SINGLE_QUOTE: "'"
  };

  static const Map<int, String> _SPECIAL_KEYS = const {
    KeyCode.F1: 'F1',
    KeyCode.F2: 'F2',
    KeyCode.F3: 'F3',
    KeyCode.F4: 'F4',
    KeyCode.F5: 'F5',
    KeyCode.F6: 'F6',
    KeyCode.F7: 'F7',
    KeyCode.F8: 'F8',
    KeyCode.F9: 'F9',
    KeyCode.F10: 'F10',
    KeyCode.F11: 'F11',
    KeyCode.F12: 'F12',
    KeyCode.TAB: 'tab',
    KeyCode.END: 'end',
    KeyCode.HOME: 'home',
    KeyCode.ESC: 'esc',
    KeyCode.INSERT: 'insert',
    KeyCode.LEFT: 'left',
    KeyCode.RIGHT: 'right',
    KeyCode.UP: 'up',
    KeyCode.DOWN: 'down',
    KeyCode.PAGE_DOWN: 'pagedown',
    KeyCode.PAGE_UP: 'pageup',
    KeyCode.PAUSE: 'pause',
    KeyCode.PRINT_SCREEN: 'printscreen',
    KeyCode.DELETE: 'delete',
    KeyCode.BACKSPACE: 'delete'
  };


  /**
   * The Factory constructor for making a new ReactiveKeyboard object
   *
   * Takes a target element to observe keyboard events from and some named
   * parameters to aid in the configuration of the ReactiveKeyboard. Optional
   * named argmuments are as follows:
   *  * allowShiftOnlyHotKeys = false: Whether or not to capture shift only
   *    hot key modifiers--excludes shift+_SPECIAL_KEYS
   *  * allowAltKeyPress = false: Whether or not to allow `alt` key presses
   *    through the `keyStream`
   *  * allowEnterKeyPress = false: Whether or not to include the enter key
   *    as part of the line for the `lineStream`
   *  * navKeys = NUM_NAV: A map of keys to filter for in the `navStream`
   *  * delKeys = DEFAULT_DEL_KEYS
   *
   *     var keyboard = new ReactiveKeyboard(query("body"))
   */
  factory ReactiveKeyboard(
      Element target, {
        bool allowShiftOnlyHotKeys: false,
        bool allowAltKeyPress: false,
        bool allowEnterKeyPress: false,
        Map<int, int> navKeys: NUM_NAV,
        List<int> delKeys: DEFAULT_DEL_KEYS,
        Stream<KeyboardEvent> keyPressStream,
        Stream<KeyboardEvent> keyUpStream,
        Stream<KeyboardEvent> keyDownStream
      })
  {
    //@todo: make sure we don't need to do anything special for input or textareas

    var rkp = keyPressStream != null ? keyPressStream : target.onKeyPress;
    var rku = keyUpStream    != null ? keyUpStream    : target.onKeyUp;
    var rkd = keyDownStream  != null ? keyDownStream  : target.onKeyDown;

    rkd = rkd.map((key) {
      if (delKeys.contains(key.keyCode)) {
        key.preventDefault();
      }

      return key;
    });

    var rkc = StreamExt.merge(StreamExt.merge(rkp, rku), rkd).asBroadcastStream();

//    var rkc = rkp.transform(new MergeAll(3, [rku, rkd])).asBroadcastStream();

    return new ReactiveKeyboard._(
      target,
      rkp,
      rku,
      rkd,
      rkc,
      allowShiftOnlyHotKeys: allowShiftOnlyHotKeys,
      allowAltKeyPress: allowAltKeyPress,
      allowEnterKeyPress: allowEnterKeyPress,
      navKeys: navKeys,
      delKeys: delKeys
    );
  }


  ReactiveKeyboard._(
      this._target,
      this.rawKeyPressStream,
      this.rawKeyUpStream,
      this.rawKeyDownStream,
      this.rawKeyCombinedStream,
      { allowShiftOnlyHotKeys, allowAltKeyPress, allowEnterKeyPress, navKeys, delKeys })
          : this.allowShiftOnlyHotKeys = allowShiftOnlyHotKeys,
            this.allowAltKeyPress = allowAltKeyPress,
            this.allowEnterKeyPress = allowEnterKeyPress,
            this.navKeys = navKeys,
            this.delKeys = delKeys;

  /**
   * A getter for `lineBuffer`.
   *
   * The string is an observable buffer for the lineStream
   */
  String get lineBuffer => _lineBuffer;

  /**
   * A setter for `lineBuffer`.
   *
   * The string is an observable buffer for the lineStream.  Set triggers change
   */
  set lineBuffer(line) {
    if (line != _lineBuffer) {
      _lineBuffer = notifyPropertyChange(const Symbol('lineBuffer'),
          _lineBuffer, line);

      _htmlLineBuffer = notifyPropertyChange(const Symbol('htmlLineBuffer'),
          _htmlLineBuffer, new HtmlEscape().convert(line).replaceAll(' ', '&nbsp;'));
    }
  }

  /**
   * A getter for `htmlLineBuffer`.
   *
   * The string is an observable buffer for the lineStream
   */
  String get htmlLineBuffer => _htmlLineBuffer;


  /**
   * A getter for `keyStream`.
   *
   * The stream returned will include all key press events except for the
   * control key and only the alt key if `allowAltKeyPress` was set to true
   * in the constructor
   */
  Stream<String> get keyStream {
    return _streamMemos.putIfAbsent("key", () {
      return rawKeyCombinedStream.where((key) {
        return (key.type == KEY_PRESS && !key.ctrlKey
            && ( !key.altKey || (allowAltKeyPress && key.altKey))
            && (allowEnterKeyPress || !_ENTER_KEYS.contains(key.keyCode)));
      }).map((key) => new String.fromCharCode(key.charCode));
    });
  }

  /**
   * A getter for `htmlKeyStream`.
   *
   * The stream returned will include all key press events except for the
   * control key and only the alt key if `allowAltKeyPress` was set to true
   * in the constructor, along with HTML characters escaped for easy printing
   */
  Stream<String> get htmlKeyStream => keyStream.transform(new HtmlEscape())
      .map((str) => str == ' ' ? '&nbsp;' : str );


  /**
   * A getter for `htmlLineStream`
   *
   * The stream returned will be a stream of lines that will be the buffered
   * keyboard input up until an enter key was pressed. This stream will also
   * correctly handle deletion keys by removing the propper characters from
   * the buffered input. If the `allowEnterKeyPress` was set to true in the
   * construction of this object then the buffered lines will contain the
   * trailing enter keys.
   */
  Stream<String> get htmlLineStream =>
      lineStream.transform(new HtmlEscape()).map((str) =>
          str.replaceAll(' ', '&nbsp;'));

  /**
   * A getter for `lineStream`
   *
   * The stream returned will be a stream of lines that will be the buffered
   * keyboard input up until an enter key was pressed. This stream will also
   * correctly handle deletion keys by removing the propper characters from
   * the buffered input. If the `allowEnterKeyPress` was set to true in the
   * construction of this object then the buffered lines will contain the
   * trailing enter keys.
   */
  Stream<String> get lineStream {
    var lineTransformer;
    {
      var _line = lineBuffer;
      var THIS = this;

      lineTransformer = new StreamTransformer.fromHandlers(handleData: (key, sink) {
        if (key.type == KEY_PRESS
            && (allowEnterKeyPress || !_ENTER_KEYS.contains(key.keyCode))) {
          THIS.lineBuffer = _line += new String.fromCharCode(key.charCode);
        } else if (key.type == KEY_DOWN) {
          if (_line.length > 0 && delKeys.contains(key.keyCode)) {
            THIS.lineBuffer = _line = _line.substring(0, _line.length - 1);
          } else if (_ENTER_KEYS.contains(key.keyCode)) {
            sink.add(_line);
            THIS.lineBuffer = _line = '';
          }
        }
      });
    }

    return  rawKeyCombinedStream.transform(lineTransformer);
  }


  /**
   * A getter for the `navStram`
   *
   * The stream returned will only consist of the ones specified in the
   * `navKeys` parameter used to construct this object.
   */
  Stream<int> get navStream {
    return _streamMemos.putIfAbsent("nav", () {
      return rawKeyCombinedStream.where((key) {
        return key.type == KEY_DOWN && navKeys.containsKey(key.keyCode);
      }).map((key) => navKeys[key.keyCode]);
    });
  }


  /**
   * A getter for the `hotKeyStream`
   *
   * The stream returned will be a stream of strings such that each string
   * emitted will be the human readable representation of the key presses
   * such that they are prefixed by their modifiers.
   */
  Stream<String> get hotKeyStream {
    return _streamMemos.putIfAbsent("hotKey", () {
      var isKeyUp = (KeyboardEvent key) => key.type == KEY_UP;

      var normalizer = (KeyboardEvent key) => [key, ""];

      var modifier = (String modifier, Function predicate) {
        return (List tuple) {
          if (predicate(tuple[0])) {
            return [tuple[0], tuple[1] + modifier + '+'];
          } else {
            return tuple;
          }
        };
      };

      var ifHasModifiers = (Function success) {
        return (List tuple) {
          if (tuple[1].length > 0) {
            return success(tuple);
          } else {
            return tuple;
          }
        };
      };

      var characterCodeInRange = (String start, String end, int n) {
        return n >= start.codeUnitAt(0) && n <= end.codeUnitAt(0);
      };

      var isAlphaNumeric = (int code) {
        return characterCodeInRange('A', 'Z', code) ||
               characterCodeInRange('0', '9', code);
      };

      var addIf = (Function predicate) {
        return (List tuple) {
          if (predicate(tuple[0].keyCode)) {
            return [tuple[0],
                tuple[1] + new String.fromCharCode(tuple[0].keyCode)];
          } else {
            return tuple;
          }
        };
      };

      var finalFilter = (List tuple) {
        return (
            _SPECIAL_KEYS.containsKey(tuple[0].keyCode)
              || (
                  allowShiftOnlyHotKeys
                  || !tuple[1].startsWith('shift+')
              )
            ) && (
                tuple[1].length > 0
                && !tuple[1].endsWith('+')
        );

      };

      return rawKeyCombinedStream
        .where(isKeyUp)
        .map(normalizer)
        .map(modifier("alt", (KeyboardEvent key) => key.altKey))
        .map(modifier("altgr", (KeyboardEvent key) => key.altGraphKey))
        .map(modifier("ctrl", (KeyboardEvent key) => key.ctrlKey))
        .map(modifier("meta", (KeyboardEvent key) => key.metaKey))
        .map(modifier("shift", (KeyboardEvent key) => key.shiftKey))
        .map(ifHasModifiers(addIf((int code) => isAlphaNumeric(code))))
        .map(ifHasModifiers(addIf((int code) => _COMBO_KEYS.containsKey(code))))
        .map((List tuple) => _SPECIAL_KEYS.containsKey(tuple[0].keyCode) ?
            [tuple[0], tuple[1] + _SPECIAL_KEYS[tuple[0].keyCode]] : tuple)
        .where(finalFilter)
        .map((List tuple) => tuple[1]);
    });
  }

}
