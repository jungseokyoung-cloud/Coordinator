//
//  Container.swift
//  Coordinator
//
//  Created by jung on 1/16/25.
//

public protocol Containable: AnyObject {}

/// `Coordinator`, `ViewController`, `ViewModel`에서 필요한 의존성을 들고 있으며, `Coordinator`생성을 담당하는 객체입니다.
open class Container<DependencyType> {
  /// 부모에게 요구하는 의존성입니다.
  public let dependency: DependencyType
  
  public init(dependency: DependencyType) {
    self.dependency = dependency
  }
}
