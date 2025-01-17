// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Coordinator",
  platforms: [.iOS(.v15)],
  products: [
    .library(
      name: "Coordinator",
      targets: ["Coordinator"]
    ),
  ],
  targets: [
    .target(name: "Coordinator")
  ],
  swiftLanguageModes: [.v5]
)
