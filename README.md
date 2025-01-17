Coordinator 패턴 SPM 라이브러리입니다.

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Description](#description)
- [Usage](#usage)

## Requirements

- iOS 13.0+

## Installation

- Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/jungseokyoung-cloud/Coordinator.git", .upToNextMajor(from: "1.0.0"))
]
```

## Description
크게 `Container`와 `Coordinator`로 구성되어 있습니다. 
- `Container`: 의존성 바구니 역할을 담당하고, 내부에서 필요한 객체 생성을 담당합니다. 필요한 경우, 부모에게 의존성을 요청합니다.
- `Coordinator`: Routing 역할을 담당하며, 각 Coordinator들은 트리형태로 부모 자식 관계를 이룹니다. 이로 인해 탈부착이 용이합니다.

기존 Coordinator 구조는 아래와 같이 내부에서 Routing로직을 담당하게 됩니다. 
```swift 
func start(at navigation: UINavigationController) {
 navigation.pushViewController(self.viewController, animated: true)
}
```
이로 인해 다음과 같은 불편함을 느꼈습니다. 
- 한가지 방식으로만 Routing이 가능한 문제 
- 사용하는 곳이 아닌 사용되는 Coordinator에서 Routing방식을 결정하는 문제점 
- UIKit에 대한 의존성 

위의 문제들을 해결하기 위해, 해당 Coordinator에선 부모 Coordinator에서 Routing로직을 결정하게 됩니다. 
이로 인해, 재사용성은 증가하게 되며, 여러 방식으로 Routing이 가능해지게 됩니다. 
자세한 내용은 [Usage](#usage)에서 확인바랍니다.

자세한 과정 및 구현 과정들은 아래 기술 블로그에서 확인해볼 수 있습니다.
- [Coordinator](https://seokyoungg.tistory.com/100) 
- [Coordinator 리팩토링](https://seokyoungg.tistory.com/110)

## Usage
많은 파일들이 생성되기에 해당 template을 추가해주면 편하게 사용할 수 있습니다. 
[Coordinator Xcode Templates zip](https://github.com/user-attachments/files/18450179/Coordinator.zip)

- 터미널을 통해 `cd ~/Library/Developer/Xcode/Templates/`으로 이동
- 해당 디렉토리에 'File Templates'로 이동 (없다면 생성)
- 위의 zip파일을 압축을 풀어 File Templates안으로 위치

### Container  
Coordinator들은 트리구조를 통해 부모 자식 관계를 형성하기 때문에, 부모에게 의존성을 요구할 수 있도록 구현해주었습니다. 
이로인해, Compositional Root에서 의존성을 조립해줄 수 있으며, 인터페이스와 구현부의 분리가 더 용이합니다.


우선, Dependency를 통해 부모에게 의존성을 요구합니다.
```swift 
protocol LogInDependency {
  // 부모에게 필요한 의존성들을 요구하는 곳입니다. 
}
```

다음으로 Container는 내부에서 필요한 객체 생성을 담당합니다.
```swift 
protocol LogInContainable: Containable {
  func coordinator(listener: LogInListener) -> ViewableCoordinating
}

final class LogInContainer:
  Container<LogInDependency>,
  LogInContainable {
  func coordinator(listener: LogInListener) -> ViewableCoordinating {
    let viewControllerable = LogInViewController()
    
    let coordinator = LogInCoordinator(viewControllerable: viewControllerable)
    coordinator.listener = listener
    return coordinator
  }
}
```

#### 부모에게 의존성 요구 
부모에게 의존성을 요구하는 경우, 아래와 같이 필요한 의존성들을 명시합니다.
```swift 
protocol LogInDependency: Dependency {
  var signUpContainable: SignUpContainable { get }
  var logInUseCase: LogInUseCase { get }
}

final class LogInContainer:
  Container<LogInDependency>,
  LogInContainable {
  public func coordinator(listener: LogInListener) -> ViewableCoordinating {
    let viewModel = LogInViewModel(useCase: dependency.logInUseCase)
    let viewControllerable = LogInViewController(viewModel: viewModel)

    
    let coordinator = LogInCoordinator(
      viewControllerable: viewControllerable,
      // 부모에게 전달받은 의존성 사용
      signUpContainable: dependency.signUpContainable,
    )
    coordinator.listener = listener
    return coordinator
  }
}
```

#### 부모에서 의존성 주입
다음으로 부모에서는 다음과 같이 의존성을 생성합니다. 이때, 부모 Conteiner는 자식의 Dependency타입을 채택해야 합니다. 
```swift 
final class AppContainer:
  Container<AppDependency>,
  AppContainable,
  LogInDependency {
  
  func coordinator() -> ViewableCoordinating { ... }
  
  // MARK: - Containable
  ...
  
  lazy var signUpContainable: SignUpContainable = {
    return SignUpContainer(dependency: self)
  }()
  
  
  // MARK: - UseCase
  lazy var logInUseCase: LogInUseCase = {
    return LogInUseCase()
  }()
}
``` 

### Coordinator  
Coordinator 객체는 실제 라우팅 역할을 담당합니다. 따라서, `UIViewController` 혹은 `UINavigationController`에 의한 UIKit에 대한 의존성이 발생하게 됩니다. 
Coordinator에선 UIKit에 대한 의존성을 없애고자 다음과 같은 2가지 객체가 존재합니다. 
- `ViewControllerable`: `UIViewController`에 대한 랩핑 프로토콜입니다.
- `NavigationControllerable`: `UINavigationController`에 대한 랩핑 클래스입니다.

이러한 Coordinator는 2가지로 분리됩니다. 
- `Coordinator`: View가 없는 경우의 Coordinator 입니다.
- `ViewableCoordinator`: View가 있는 경우의 Coordinator입니다. 

기본 구조는 다음과 같이 구성됩니다. 
- Listener: 부모에게 이벤트를 전달하고 싶다면, 해당 프로토콜에 명시합니다. 부모 Coordinator는 자식의 listener를 채택해야 합니다. 
- Presentable: Coordinator에서 ViewController에서 이벤트를 보내고 싶을 때, 해당 프로토콜을 사용합니다. 구체타입이 아닌, 프로토콜을 통해 필요한 인터페이스만 알게 됩니다. 
- Coordinator

#### 자식 Cooridnator
**[Coordinator]**
자식 Coordinator는 아래와 같이 구현합니다. 
앞서 말했듯, `Coordinator`는 View가 없는 경우입니다. 
```swift 
final class SignUpCoordinator: Coordinator {
  weak var listener: SignUpListener?
  ...
  init(
    navigationControllerable: NavigationControllerable,
    enterEmailContainable: EnterEmailContainable,
    enterIdContainable: EnterIdContainable,
    enterPasswordContainable: EnterPasswordContainable
  ) {
    self.navigationControllerable = navigationControllerable
    self.enterEmailContainable = enterEmailContainable
    self.enterIdContainable = enterIdContainable
    self.enterPasswordContainable = enterPasswordContainable
    super.init()
  }
  
  override func start() {
    attachEnterEmail()
  }
  
  override func stop() {
    detachEnterPassword()
    detachEnterId()
    detachEnterEmail()
  }
  ...
}
```
이때, 부모에게 붙었을때, `start()`메서드가 호출되고, 부모에게 제거되었을 때 `stop()`메서드가 호출됩니다. 

만약 부모에게 이벤트를 보내고 싶다면, Lisenter를 통해 전달합니다. 
```swift 
protocol SignUpListener: AnyObject {
  func didFinishSignUp(userName: String)
  func didTapBackButtonAtSignUp()
}
```

**[ViewableCoordinator]**
`ViewableCoordinator`는 View가 있는 경우의 Coordinator입니다. 

우선, Presentable을 생성해줍니다. 
```swift 
protocol LogInPresentable {
  func configureUserName(_ name: String)
}

final class LogInCoordinator: ViewableCoordinator<LogInPresentable> 
```

Coordinator 내부적으로 ViewController에 이벤트를 보내고 싶을때는, 이 Presentable을 사용합니다. 
```swift 
func start() {
  presenter.configureUserName(userName)
}
```

해당 Coordinator의 ViewController는 다음과 같이 `ViewControllerable`타입과 `Presentable`을 채택해주어야 합니다. 
```swift 
final class LogInViewController: UIViewController: ViewControllerable, LogInPresentable { ... }
```
나머지 동작은 Coordinator와 같습니다. 


#### 부모 Coordinator 
우선, 공통적으로 부모 Coordinator에선 자식의 Listener를 채택해주어야 합니다. 
```swift 
extension LogInCoordinator: SignUpListener {
  func didFinishSignUp(userName: String) {
    detachSignUp()
    listener?.didFinishLogIn(userName: userName)
  }
  
  func didTapBackButtonAtSignUp() {
    detachSignUp()
  }
}
```
또한, 부모 Coordinator에선 자식의 Coordinator를 생성 및 라우팅을 해주어야 합니다. 
따라서, 부모는 다음과 같이 자식의 Container를 프로퍼티로 들고 있습니다. 
```swift 
final class LogInCoordinator: ... {
  private let signUpContainer: SignUpContainable
}
```
부모는 필요할 때, SignUpContainer를 통해 Coordinator를 생성합니다. 
```swift 
func attachSignUp() {
  let coordinator = signUpContainer.coordinator(listener: self)
  ...
}
```

이떄의 Routing 로직은 자식이 `Coordinator`냐, `ViewableCoordinator`냐에 따라 달라지게 됩니다.
**[자식이 Coordinator]**
자식이 Coordinator의 경우에는 단순 자식만 attach하면 됩니다. 
```swift 
final class LogInCoordinator: ... {
  private let signUpContainer: SignUpContainable
  private var signUpCoordinator: Coordinating? // 자식이 두번 attach 혹은 detach되는 것을 방지하기 위함.
  
  ...
  func attachSignUp() {
    guard signUpCoordinator == nil else { return }
    let navigation = NavigationControllerable()
    let coordinator = signUpContainer.coordinator(listener: self, navigation: navigation)
    
    addChild(coordinator)
    self.signUpCoordinator = coordinator
  }
  
  func detachSignUp() {
    guard let coordinator = signUpCoordinator else { return }
    removeChild(coordinator)
    self.signUpCoordinator = nil
  }
}
```
**[자식이 ViewableCoordinator]**
자식이 ViewableCoordinator의 경우, 부모는 ViewableCoordinating?으로 알고 있게 됩니다. 
```swift 
final class LogInCoordinator: ... {
  private let findIdContainer: FindIdContainable
  private var findIdCoordinator: ViewableCoordinating?
  
  ...
  
  func attachFindId() {
    guard findIdCoordinator == nil else { return }
    let coordinator = findIdContainer.coordinator(listener: self)
    addChild(coordinator)

    self.viewControllerable.present(
      coordinator.viewControllerable,
      modalPresentationStyle: .overFullScreen,
      animated: true
    )
    self.findIdCoordinator = coordinator
  }
  
  func detachFindId() {
    guard let coordinator = findIdCoordinator else { return }
    removeChild(coordinator)
    coordinator.viewControllerable.dismiss(animated: true)
    self.findIdCoordinator = nil
  }
```
Coordiantor 내에서 ViewController로 이벤트를 전달하고 싶을 때, `presenter`를 사용했다면, 
외부에서 라우팅을 위해선, `viewConrollerable`을 사용합니다.


### 모듈화 
모듈화는 정말 간편합니다. 
2가지 인터페이스만 외부로 분리시켜주면 됩니다. 
```swift 
LogInInterfaces.swift

public protocol LogInContainable: Containable {
  func coordinator(listener: LogInListener) -> ViewableCoordinating
}

public protocol LogInListener: AnyObject {
  func didFinishLogIn(userName: String)
  func didTapBackButtonAtLogIn()
}
```

또한, 의존성을 조립해주는 부모의 Container에선 다음과 같은 2개의 생성을 담당해야 합니다. 
- 자식이 Dependency에 요구한 의존성 
- 자식의 Container 객체 

따라서, 다음과 같이 Dependency와 Container 객체도 public으로 접근제한자를 변경해주면 됩니다. 
```swift 
public protocol LogInDependency { ... }

public final class LogInContainer ... { 
  public func coordinator(listener: LogInListener) -> ViewableCoordinating { ... }
}
```
이를 제외한 나머지는 Internal로 선언해도 가능합니다. 
최종적으로 외부 모듈에 대한 노출을 최소화 함으로 변경에서 비교적 자유로우며, 모듈화에 있어서도 간편합니다.
