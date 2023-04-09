# ``makataForm``

Handle creating, recording, and validating form fields with ease.

## Topics

### Creating the form

Conform ``Formable`` to enable form handling to your code, with ``FormHandler`` serving as the object managing the recorded form state.

- ``Formable``
- ``FormHandler``

### Defining Bindings

A binding is a contract from your user interface to the form handler.

- ``Binding``
- ``FieldTransformable``
- ``FieldFormattable``

### Enabling Validation

Validations strengthen your form handling by checking if all fields satisfy validation constraints.

- ``FormHandler/setValidationHandler(_:)``
- ``FormValidation``
- ``FieldValidator``
- ``FieldError``

### Observing Side-Effects

Side-effects can be triggered when a specific field's value is changed.

- ``FormHandler/setObserverHandler(_:)``
- ``FormObserver``

### Using Partial Values as Form Fields

A parital value is used when a field needs type safety but still allows incomplete representation that does not satisfy such type safety to happen.

- ``FieldPartialValue``
- ``EnsureCompleteFields``
- ``FieldPartialValueKeyPath``
