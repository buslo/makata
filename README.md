# makata

Foundations for writing iOS apps in the least amount of time

## What's in it?

###  **Makata Form** for handling forms

```swift
struct TheForm {
    var name: String
    var email: String
}

class YourViewModel: Formable {
    let formHandler = FormHandler<TheForm>(initial: .init(name: "", email: ""))
        .setValidationsHandler(
            FormValidation()
                .validations(for: \.name, are: .notEmpty, .atLeast(6.characters))
                .validations(for: \.email, are: .notEmpty, .email)
        )
}

class YourController {
    let yourViewModel = YourViewModel()
    
    var nameInputFieldState: Lifetimeable?
    var emailInputFieldState: Lifetimeable?
    
    func loadView() {
        nameInputFieldState = nameInputField
            .textChanges(Binding(source: yourViewModel.formHandler, to: \.name))
        
        emailInputFieldState = emailInputField
            .textChanges(Binding(source: yourViewModel.formHandler, to: \.email))

        yourViewModel.formHandler { form, state in
            submitButton.isEnabled = state.isValid
        }
    }
}
```

### **Makata User Interface** for rapidly creating views:

```swift
class YourController: Controller<YourViewModel> {
    override func loadView() {
        super.loadView()
        
        view
            .addSubview(
                UIButton(configuration: .pilled().withTitle("Click me!"), primaryAction: clickMeAction())
                    .defineConstraints { make in
                        make.center
                            .equalToSuperview()
                    }
            )
            .addSubview(
                UIStackView
                    .vertical {
                        UILabel()
                            .content("My name is")
                        UILabel()
                            .content("Makata!")
                            .contentSize(.body, weight: .bold)
                    }
            )
    }
    
    func clickMeAction() -> UIAction {
        .init { _ in
            // your button action
        }
    }
}
```

### **Makata Interaction** for useful utilities

```swift
enum Routes {
    case success
    case anotherStep
}

class YourViewModel: Routeable {
    func process() async {
        // do some processing
        
        await updateRoute(to: .success)
    }
}

class YourViewController: Controller<YourViewModel> {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client.routeHandler { nextRoute in
            switch nextRoute {
            case .success:
                navigation.pop()
            case .anotherStep:
                navigation.push(YourSecondStepViewController())
            }
        }
    }
}

struct ScreenState {
    let name: String
}

class YourLoadingViewModel: Stateable {
    let stateHandler = StateHandler<ScreenState>(initial: .init(name: ""))
    
    func initialize() {
        Task {
            let result = await someNetworkCall()
            await updateState(to: .init(name: result.name))
        }
    }
}

class YourLoadingViewController: Controller<YourLoadingViewModel> {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client.stateHandler { [unowned nameLabel] state in
            nameLabel.text = state.name
        }
    }
}
```
