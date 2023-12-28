import 'dart:js_interop';

import 'package:js/js.dart' as js;
import 'package:js/js_util.dart' as util;
import 'package:web/web.dart';

import 'extensions.dart';
import 'form.dart';
import 'lifecycle_callbacks.dart';

final htmlElement = util.getProperty(window, 'HTMLElement');
final htmlReflect = util.getProperty(window, 'Reflect');
final htmlObject = util.getProperty(window, 'Object');

typedef ComponentConstructor<T> = T Function(HTMLElement element);

/// Adds a definition for a custom element to the custom element registry, mapping its
/// [name] to the [constructor] that will be used to create it.
/// 
/// This is a Dart counterpart to CustomElementRegistry.define in JavaScript. It allows
/// a Dart class to be used as a custom element instead of a JavaScript class.
/// 
/// Does not support extending built-in elements.
/// 
/// Custom element lifecycle callbacks can be defined by implementing the interfaces:
/// [ConnectedCallback], [DisconnectedCallback], [AttributeChangedCallback], and [AdoptedCallback].
/// 
/// Example:
/// ```dart
/// class MyAutonomousElement implements ConnectedCallback {
///   MyAutonomousElement(HTMLElement element);
/// 
///   @override
///   void connectedCallback() {}
/// }
/// // ...
/// define('my-autonomous-element', MyAutonomousElement.new);
/// ```
/// 
/// Since things such as static fields and functions cannot be automatically transferred from
/// the Dart class definition to the underlying JS custom element that gets defined, the
/// [staticProperties] and [exportedFunctions] parameters can be used to define them alongside
/// the custom element definition.
/// 
/// The [staticProperties] parameter, for example, can be used to implement the [AttributeChangedCallback]:
/// ```dart
/// class MySizedElement implements AttributeChangedCallback {
///   MySizedElement(HTMLElement element);
/// 
///   @override
///   void attributeChangedCallback(String name, Object? oldValue, Object? newValue, String? namespace) {
///     print('$name: $oldValue -> $newValue');
///   }
/// }
/// // ...
/// define('my-sized-element', MySizedElement.new, 
///     staticProperties: {'observedAttributes': ['size']});
/// ```
/// 
/// To define a form-associated custom element, set the static property `formAssociated` to true and
/// extend the [FormAssociatedCustomElement] class. Form-associated lifecycle callbacks can be defined
/// by implementing [FormAssociatedCallback], [FormDisabledCallback], [FormResetCallback], and
/// [FormStateRestoreCallback].
void define<T>(String name, ComponentConstructor<T> constructor, {
  Map<String, Object>? staticProperties,
  Map<String, Function>? exportedFunctions,
}) {
  bool firstInstantiation = true;

  // Constructor for the actual JavaScript custom element
  //
  // We can't use an actual Dart class as the subtype, but we can attach one as a property
  // and proxy the lifecycle callbacks to the Dart class 
  Object ctor(Object self) {
    final selfCtor = util.getProperty(self, 'constructor');
    final element = util.callMethod(htmlReflect, 'construct', [htmlElement, const [], selfCtor]) as HTMLElement;

    final dartClass = constructor(element);
    util.setProperty(element, '__#dartComponent', dartClass);

    // We don't know what lifecycle callbacks T implements until we actually instantiate one.
    // On the first instantiation, remove any unused callbacks from the prototype. This may or
    // may not give a performance benefit depending on the browser implementation of custom elements
    //
    // If there becomes a way to infer implementations from just the generic type, this can be removed
    if (firstInstantiation) {
      firstInstantiation = false;

      final proto = util.getProperty(self, '__proto__');

      if (dartClass is! ConnectedCallback) {
        util.delete(proto, 'connectedCallback');
      }

      if (dartClass is! DisconnectedCallback) {
        util.delete(proto, 'disconnectedCallback');
      }

      if (dartClass is! AttributeChangedCallback) {
        util.delete(proto, 'attributeChangedCallback');
      }

      if (dartClass is! AdoptedCallback) {
        util.delete(proto, 'adoptedCallback');
      }

      if (staticProperties != null && staticProperties['formAssociated'] == true) {
        if (dartClass is! FormAssociatedCallback) {
          util.delete(proto, 'formAssociatedCallback');
        }

        if (dartClass is! FormDisabledCallback) {
          util.delete(proto, 'formDisabledCallback');
        }

        if (dartClass is! FormResetCallback) {
          util.delete(proto, 'formResetCallback');
        }

        if (dartClass is! FormStateRestoreCallback) {
          util.delete(proto, 'formStateRestoreCallback');
        }
      }
    }

    return element;
  }

  // Set up proper prototype inheritance of HTMLElement
  final elementClass = js.allowInteropCaptureThis(ctor);
  util.setProperty(elementClass, '__proto__', htmlElement);

  final elementProto = util.getProperty(elementClass, 'prototype');
  util.setProperty(elementProto, '__proto__', util.getProperty(htmlElement, 'prototype'));
  util.setProperty(elementProto, 'constructor', elementClass);

  // Proxy custom element lifecycle callbacks (we'll remove unused callbacks later)
  util.setProperty(elementProto, 'connectedCallback', js.allowInteropCaptureThis((Element self) {
    final dartClass = self.getDartComponent();
    if (dartClass is ConnectedCallback) {
      dartClass.connectedCallback();
    }
  }));
  
  util.setProperty(elementProto, 'disconnectedCallback', js.allowInteropCaptureThis((Element self) {
    final dartClass = self.getDartComponent();
    if (dartClass is DisconnectedCallback) {
      dartClass.disconnectedCallback();
    }
  }));
  
  util.setProperty(elementProto, 'attributeChangedCallback', js.allowInteropCaptureThis(
    (Element self, name, oldValue, newValue, namespace) {
      final dartClass = self.getDartComponent();
      if (dartClass is AttributeChangedCallback) {
        dartClass.attributeChangedCallback(name, oldValue, newValue, namespace);
      }
    }));
  
  util.setProperty(elementProto, 'adoptedCallback', js.allowInteropCaptureThis(
    (Element self, oldDocument, newDocument) {
      final dartClass = self.getDartComponent();
      if (dartClass is AdoptedCallback) {
        dartClass.adoptedCallback(oldDocument, newDocument);
      }
    }));

  // Proxy form-associated element methods
  if (staticProperties != null && staticProperties['formAssociated'] == true) {
    _defineProperty(elementProto, 'value', {
      'get': js.allowInteropCaptureThis((Element self) {
        return self.getDartComponent<FormAssociatedCustomElement>()?.value;
      }),
      'set': js.allowInteropCaptureThis((Element self, value) {
        self.getDartComponent<FormAssociatedCustomElement>()?.value = value;
      })
    });

    _defineGetter(elementProto, 'form', (self) => self.getDartComponent<FormAssociatedCustomElement>()?.form);
    _defineGetter(elementProto, 'name', (self) => self.getDartComponent<FormAssociatedCustomElement>()?.name);
    _defineGetter(elementProto, 'type', (self) => self.getDartComponent<FormAssociatedCustomElement>()?.type);
    _defineGetter(elementProto, 'validity', (self) => self.getDartComponent<FormAssociatedCustomElement>()?.validity);
    _defineGetter(elementProto, 'validationMessage', (self) => self.getDartComponent<FormAssociatedCustomElement>()?.validationMessage);
    _defineGetter(elementProto, 'willValidate', (self) => self.getDartComponent<FormAssociatedCustomElement>()?.willValidate);

    util.setProperty(elementProto, 'checkValidity', js.allowInteropCaptureThis((Element self) {
      return self.getDartComponent<FormAssociatedCustomElement>()?.checkValidity();
    }));

    util.setProperty(elementProto, 'reportValidity', js.allowInteropCaptureThis((Element self) {
      return self.getDartComponent<FormAssociatedCustomElement>()?.reportValidity();
    }));

    util.setProperty(elementProto, 'formAssociatedCallback', js.allowInteropCaptureThis(
      (Element self, form) {
        final dartClass = self.getDartComponent();
        if (dartClass is FormAssociatedCallback) {
          dartClass.formAssociatedCallback(form);
        }
      }));
    
    util.setProperty(elementProto, 'formDisabledCallback', js.allowInteropCaptureThis(
      (Element self, disabled) {
        final dartClass = self.getDartComponent();
        if (dartClass is FormDisabledCallback) {
          dartClass.formDisabledCallback(disabled);
        }
      }));

    util.setProperty(elementProto, 'formResetCallback', js.allowInteropCaptureThis(
      (Element self) {
        final dartClass = self.getDartComponent();
        if (dartClass is FormResetCallback) {
          dartClass.formResetCallback();
        }
      }));
    
    util.setProperty(elementProto, 'formStateRestoreCallback', js.allowInteropCaptureThis(
      (Element self, state, mode) {
        final dartClass = self.getDartComponent();
        if (dartClass is FormStateRestoreCallback) {
          dartClass.formStateRestoreCallback(state, mode);
        }
      }));
  }

  // Set static properties
  if (staticProperties != null) {
    for (final entry in staticProperties.entries) {
      util.setProperty(elementClass, entry.key, entry.value);
    }
  }

  // Set exported functions
  if (exportedFunctions != null) {
    for (final entry in exportedFunctions.entries) {
      util.setProperty(elementProto, entry.key, js.allowInteropCaptureThis(entry.value));
    }
  }

  // Define custom element
  window.customElements.define(name, elementClass as JSFunction);
}

void _defineProperty(Object obj, String name, Map<String, dynamic> descriptor) {
  util.callMethod(htmlObject, 'defineProperty', [obj, name, descriptor.jsify()]);
}

void _defineGetter(Object obj, String name, dynamic Function(Element self) getter) {
  util.callMethod(htmlObject, 'defineProperty', [obj, name, {'get': js.allowInteropCaptureThis(getter)}.jsify()]);
}
