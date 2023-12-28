import 'package:meta/meta.dart';
import 'package:web/web.dart';

abstract class FormAssociatedCustomElement<T> {
  @protected
  final ElementInternals internals;

  final HTMLElement _element;

  FormAssociatedCustomElement(HTMLElement element)
      : _element = element,
        internals = element.attachInternals();

  T get value;
  set value(T v);

  HTMLFormElement? get form => internals.form;
  String? get name => _element.getAttribute('name');
  String get type => _element.localName;
  ValidityState get validity => internals.validity;
  String get validationMessage => internals.validationMessage;
  bool get willValidate => internals.willValidate;

  bool checkValidity() {
    return internals.checkValidity();
  }

  bool reportValidity() {
    return internals.reportValidity();
  }
}