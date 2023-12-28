import 'dart:async';
import 'dart:js_interop';

import 'package:dart_web_components/dart_web_components.dart';
import 'package:web/helpers.dart';

void main() {
  // Define custom elements
  define('my-counter-display', MyCounterDisplay.new, 
      staticProperties: {'observedAttributes': ['value']});
  define('my-counter-button', MyCounterButton.new);

  // Connect button to display
  final btn = document.querySelector('my-counter-button')!;
  final display = document.querySelector('my-counter-display')!;

  btn.addEventListener('increment', (CustomEvent evt) {
    final curVal = int.parse(display.getAttribute('value')!);
    final increment = evt.detail as int;
    display.setAttribute('value', (curVal + increment).toString());
  }.toJS);
}

class MyCounterDisplay implements AttributeChangedCallback {
  final HTMLElement _element;
  final ShadowRoot _shadow;

  MyCounterDisplay(this._element)
      : _shadow = _element.attachShadow(ShadowRootInit(mode: 'open'));

  @override
  void attributeChangedCallback(String name, Object? oldValue, Object? newValue, String? namespace) {
    // Connect 'value' attribute to our display text
    if (name == 'value') {
      print('counter display: $oldValue -> $newValue');
      _update();
    }
  }

  void _update() {
    _shadow.text = _element.getAttribute('value') ?? '';
  }
}

class MyCounterButton implements DisconnectedCallback {
  final HTMLElement _element;
  final ShadowRoot _shadow;
  late final StreamSubscription _clickSubscription;

  MyCounterButton(this._element)
      : _shadow = _element.attachShadow(ShadowRootInit(mode: 'open')) {
    // Add <button> to our shadow DOM
    final btn = document.createElement('button')
        ..innerHTML = '<slot></slot>';
    _shadow.appendChild(btn);

    // When the button is clicked, fire an 'increment' event from this custom element
    _clickSubscription = btn.onClick.listen((event) {
      _element.dispatchEvent(CustomEvent('increment', CustomEventInit(detail: 1.toJS)));
    });
  }
  
  @override
  void disconnectedCallback() {
    _clickSubscription.cancel();
  }
}
