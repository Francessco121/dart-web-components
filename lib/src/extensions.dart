import 'package:js/js_util.dart' as util;
import 'package:web/web.dart';

extension DartWebComponentElementExtensions on Element {
  /// Gets the Dart class instance associated with this custom element.
  /// 
  /// Returns null if this is not a Dart custom element.
  T? getDartComponent<T>() {
    final component = util.getProperty(this, '__#dartComponent');
    return component == null ? null : component as T;
  }
}

extension DartWebComponentDocumentFragmentExtensions on DocumentFragment {
  /// Finds the child element matching the query [selectors] and returns
  /// the Dart class instance associated with it if the element is a custom element.
  /// 
  /// Returns null if no element was  found or the element is not a Dart custom element.
  T? querySelectDartComponent<T>(String selectors) {
    // ignore: unnecessary_this
    return this.querySelector(selectors)?.getDartComponent<T>();
  }
}
