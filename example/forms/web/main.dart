import 'dart:async';
import 'dart:js_interop';

import 'package:dart_web_components/dart_web_components.dart';
import 'package:web/helpers.dart';

void main() {
  // Define custom element
  define('my-form-element', MyFormElement.new, 
      staticProperties: {'formAssociated': true});
  
  // Hook up disabled checkbox and reset button to indirectly act on the form element
  final form = document.querySelector('form') as HTMLFormElement;

  final fieldset = document.querySelector('fieldset') as HTMLFieldSetElement;
  final disabledCheck = document.getElementById('disabled-check') as HTMLInputElement;
  disabledCheck.onChange.listen((event) {
    fieldset.disabled = disabledCheck.checked;
  });

  final resetBtn = document.getElementById('reset-btn') as HTMLButtonElement;
  resetBtn.onClick.listen((event) {
    form.reset();
  });
}

class MyFormElement extends FormAssociatedCustomElement<int> 
    implements DisconnectedCallback, FormDisabledCallback, FormResetCallback {
  @override
  int get value => _value;
  @override
  set value(int v) {
    _value = v;
    _onValueChanged();
  }

  int _value = 0;

  final ShadowRoot _shadow;

  late final HTMLSpanElement _display;
  late final HTMLButtonElement _incButton;
  late final HTMLButtonElement _decButton;

  late final StreamSubscription _incSubscription;
  late final StreamSubscription _decSubscription;

  MyFormElement(super.element) 
      : _shadow = element.attachShadow(ShadowRootInit(mode: 'open', delegatesFocus: true)) {
    // Set up HTML/CSS
    _shadow.innerHTML = '''
<style>
  :host {
    display: inline-block;
  }

  span, button {
    vertical-align: middle;
  }

  :host(:invalid) {
    color: red;
  }
</style>
<span id="val"></span>
<button id="dec">-</button>
<button id="inc">+</button>
''';

    // Grab buttons/display and hook up buttons
    _display = _shadow.getElementById('val') as HTMLSpanElement;
    _incButton = _shadow.getElementById('inc') as HTMLButtonElement;
    _decButton = _shadow.getElementById('dec') as HTMLButtonElement;

    _incSubscription = _incButton.onClick.listen((event) {
      value++;
    });

    _decSubscription = _decButton.onClick.listen((event) {
      value--;
    });

    // Handle initial value
    _onValueChanged();
  }
  
  @override
  void disconnectedCallback() {
    _incSubscription.cancel();
    _decSubscription.cancel();
  }

  void _onValueChanged() {
    // Propagate value in Dart to JS form internals
    internals.setFormValue(value.toString().toJS);

    // Update display
    _display.text = value.toString();

    // Determine validity
    if (_value < 0) {
      internals.setValidity(ValidityStateFlags(customError: true), 'Value cannot be negative.');
    } else {
      internals.setValidity(ValidityStateFlags());
    }
  }
  
  @override
  void formDisabledCallback(bool disabled) {
    // Propagate disabled state to buttons
    _decButton.disabled = disabled;
    _incButton.disabled = disabled;
  }
  
  @override
  void formResetCallback() {
    value = 0;
  }
}
