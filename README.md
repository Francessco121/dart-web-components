# Dart Web Components
A proof of concept library for creating web components (custom elements) with Dart classes.

Creating a custom element requires the code to extend from the JS `HTMLElement` class. This works great in normal JS code, but is not possible to do with a Dart class. Even extending from the `HtmlElement` class found in `dart:html` (or `HTMLElement` from `package:web`) will not work. This library works around this issue by manually building a custom JS object with the correct prototype chain to extend from `HTMLElement` and then hooking methods from that custom object to a Dart class.

This library could be used to create standalone web components in Dart (to be used by non-Dart code) or for Dart-only web applications that use web components as a base (the Dart class associated with a custom element can be retrieved from the DOM via the [getDartComponent](./lib/src/extensions.dart) extension method).

> Check out the code in [define.dart](./lib/src/define.dart)! This workaround is actually pretty simple. With some codegen, the process in this file could be simplified further and tailored for each custom element class, however this library does not explore that.

> [!IMPORTANT]
> This library uses `package:web` and `package:js` instead of `dart:html` and `dart:js` respectively. Types between these packages are not compatible!

## Examples
A super simple Dart custom element could be created like this:
```dart
import 'package:dart_web_components/dart_web_components.dart';
import 'package:web/web.dart';

class MyAutonomousElement implements OnConnected {
  MyAutonomousElement(HTMLElement element);

  @override
  void onConnected() {
    print('Hello world!');
  }
}

void main() {
  define('my-autonomous-element', MyAutonomousElement.new);
}
```

Check out the [example](./example) directory for more in-depth samples.
