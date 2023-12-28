import 'package:web/web.dart';

abstract interface class ConnectedCallback { 
  /// Called when the element is connected (i.e. added to a document).
  void connectedCallback();
}

abstract interface class DisconnectedCallback {
  /// Called when the element is disconnected (i.e. removed from a document).
  void disconnectedCallback();
}

abstract interface class AttributeChangedCallback {
  /// Called when an attribute of the element that is defined by the `observedAttributes`
  /// JS static property changes.
  /// 
  /// This will also be called if an attribute already has a value when the element is first upgraded.
  void attributeChangedCallback(String name, Object? oldValue, Object? newValue, String? namespace);
}

abstract interface class AdoptedCallback {
  /// Called when the element is adopted by a different document (e.g. moved into an iframe).
  void adoptedCallback(Document oldDocument, Document newDocument);
}

abstract interface class FormAssociatedCallback {
  /// Called when the element associates with or disassociates from a form element.
  void formAssociatedCallback(HTMLFormElement? form);
}

abstract interface class FormDisabledCallback {
  /// Called when the disabled state of the element changes.
  void formDisabledCallback(bool disabled);
}

abstract interface class FormResetCallback {
  /// Called when the associated form is reset.
  void formResetCallback();
}

abstract interface class FormStateRestoreCallback {
  /// Called when the element's state should be restored ([mode] = "restore") or after a 
  /// form-filling assist feature was invoked on the element ([mode] = "autocomplete").
  void formStateRestoreCallback(dynamic state, String mode);
}
