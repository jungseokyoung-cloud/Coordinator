//
//  ViewableCoordinator.swift
//  Coordinator
//
//  Created by jung on 1/16/25.
//

import Combine

public protocol ViewableCoordinating: Coordinating {
  var viewControllerable: ViewControllerable { get }
}

/// `ViewController`가 있는 경우, 화면 전환 로직을 담당하는 객체입니다.
open class ViewableCoordinator<PresenterType>: Coordinator, ViewableCoordinating {
//  private let disposeBag = DisposeBag()
  
  /// push, present 등등 라우팅 역할을 담당하는 `ViewController`입니다.
  public let viewControllerable: ViewControllerable
  /// 내부적으로 `Coordinator`에서 `ViewController`로 이벤트를 전달할 경우 사용합니다.
  public let presenter: PresenterType
  
  public init(_ viewController: ViewControllerable) {
    self.viewControllerable = viewController
    
    guard let presenter = viewController as? PresenterType else {
      fatalError("\(viewController) should conform to \(PresenterType.self)")
    }
    
    self.presenter = presenter
    super.init()
  }
}
