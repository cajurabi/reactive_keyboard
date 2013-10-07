library reactive_keyboard;

import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'package:observe/observe.dart';

import 'package:merge_all/merge_all.dart';


class ReactiveKeyboard extends ChangeNotifierMixin {
  final Element _target;
  final Stream<KeyEvent> rawKeyCombinedStream;
  final Stream<KeyEvent> rawKeyUpStream;
  final Stream<KeyEvent> rawKeyDownStream;
  final Stream<KeyEvent> rawKeyPressStream;

  bool allowShiftOnlyHotKeys;
  bool allowAltKeyPress;
  bool allowEnterKeyPress;
  Map<KeyCode, int> navKeys;
  List<int> delKeys;

  String _lineBuffer = '';
  String _htmlLineBuffer = '';

  Stream<String> _keyStream;
  Stream<String> _lineStream;
  Stream<int>    _navStream;
  Stream<String> _hotKeyStream;

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
        List<int> delKeys: DEFAULT_DEL_KEYS
      })
  {
    //@todo: make sure we don't need to do anything special for input or textareas
    var rkp = KeyboardEventStream.onKeyPress(target);
    var rku = KeyboardEventStream.onKeyUp(target);
    var rkd = KeyboardEventStream.onKeyDown(target).map((key) {
      if ( delKeys.contains(key.keyCode)) {
        key.preventDefault();
      }

      return key;
    });

    var rkc = rkp.transform(new MergeAll(3, [rku, rkd])).asBroadcastStream();

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
      _lineBuffer = notifyPropertyChange(const Symbol('lineBuffer'),
          _lineBuffer, line);

      htmlLineBuffer = new HtmlEscape().convert(line).replaceAll(' ', '&nbsp;');
  }

  /**
   * A getter for `htmlLineBuffer`.
   *
   * The string is an observable buffer for the lineStream
   */
  String get htmlLineBuffer => _htmlLineBuffer;

  /**
   * A setter for `htmlLineBuffer`.
   *
   * The string is an observable buffer for the lineStream.  Set triggers change
   */
  set htmlLineBuffer(line) =>
      _htmlLineBuffer = notifyPropertyChange(const Symbol('htmlLineBuffer'),
          _htmlLineBuffer, line);




  /**
   * A getter for `keyStream`.
   *
   * The stream returned will include all key press events except for the
   * control key and only the alt key if `allowAltKeyPress` was set to true
   * in the constructor
   */
  Stream<String> get keyStream {
    if (_keyStream == null) {
      _keyStream = rawKeyCombinedStream.where((key) {
        return (key.type == KEY_PRESS && !key.ctrlKey
            && ( !key.altKey || (allowAltKeyPress && key.altKey))
            && (allowEnterKeyPress || !_ENTER_KEYS.contains(key.keyCode)));
      }).map((key) => new String.fromCharCode(key.charCode));
    }

    return _keyStream;
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
    if (_lineStream == null) {
      var lineTransformer;
      {
        var THIS = this;

        lineTransformer = new StreamTransformer(handleData: (key, sink) {
          if (key.type == KEY_PRESS
              && (allowEnterKeyPress || !_ENTER_KEYS.contains(key.keyCode))) {
            THIS.lineBuffer += new String.fromCharCode(key.charCode);
          } else if (key.type == KEY_DOWN) {
            if (THIS.lineBuffer.length > 0 && delKeys.contains(key.keyCode)) {
              THIS.lineBuffer = THIS.lineBuffer.substring(0, THIS.lineBuffer.length - 1);
            } else if (_ENTER_KEYS.contains(key.keyCode)) {
              sink.add(THIS.lineBuffer);
              THIS.lineBuffer = '';
            }
          }
        });
      }

      _lineStream = rawKeyCombinedStream.transform(lineTransformer);
    }

    return _lineStream;
  }

  /**
   * A getter for the `navStram`
   *
   * The stream returned will only consist of the ones specified in the
   * `navKeys` parameter used to construct this object.
   */
  Stream<int> get navStream {
    if (_navStream == null) {
      _navStream = rawKeyCombinedStream.where((key) {
        return key.type == KEY_DOWN && navKeys.containsKey(key.keyCode);
      }).map((key) => navKeys[key.keyCode]);
    }

    return _navStream;
  }


  /**
   * A getter for the `hotKeyStream`
   *
   * The stream returned will be a stream of strings such that each string
   * emitted will be the human readable representation of the key presses
   * such that they are prefixed by their modifiers.
   */
  Stream<String> get hotKeyStream {
    if (_hotKeyStream == null) {
      var hotKeyTransformer = new StreamTransformer(handleData: (KeyEvent key, sink) {
        var hk = '';

        if (key.type == KEY_UP) {
          if (key.altKey) {
            hk += 'alt+';
          }
          if (key.altGraphKey) {
            hk += 'altgr+';
          }
          if (key.ctrlKey) {
            hk += 'ctrl+';
          }
          if (key.metaKey) {
            hk += 'meta+';
          }
          if (key.shiftKey) {
            hk += 'shift+';
          }

          if (hk.length > 0) {
            if ((
                key.keyCode >= 'A'.codeUnitAt(0)
                && key.keyCode <= 'Z'.codeUnitAt(0)
              ) ||
              (
                key.keyCode >= '0'.codeUnitAt(0)
                && key.keyCode <= '9'.codeUnitAt(0)
              )
             ) {
              hk += new String.fromCharCode(key.keyCode);
            } else if (_COMBO_KEYS.containsKey(key.keyCode)) {
              hk += _COMBO_KEYS[key.keyCode];
            }
          }

          if (_SPECIAL_KEYS.containsKey(key.keyCode)) {
            hk += _SPECIAL_KEYS[key.keyCode];
          } else if (!allowShiftOnlyHotKeys && hk.startsWith('shift+')) {
            hk = '';
          }

          if (hk.length > 0 && !hk.endsWith('+')) {
            sink.add(hk);
          }
        }
      });

      _hotKeyStream = rawKeyCombinedStream.transform(hotKeyTransformer);
    }

    return _hotKeyStream;
  }

}
