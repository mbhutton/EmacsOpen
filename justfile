_default:
  @just --list

lint:
  @echo "Linting Swift files..."
  swift-format lint --strict --recursive .

format:
  @echo "Formatting Swift files..."
  swift-format format --in-place --recursive .

build-cli-release:
  @echo "Building CLI..."
  swift build --configuration release --product emacsopen -Xswiftc -diagnostic-style=llvm

build-app-release:
  @echo "Building App using Xcode..."
  # Build the app using xcodebuild
  xcodebuild -project EmacsOpen.xcodeproj -scheme EmacsOpen -quiet -configuration Release build

build-release: build-cli-release build-app-release
  @echo "All release builds completed"

update-swiftpm:
  @echo "Updating SwiftPM dependencies..."
  swift package update

update-xcode-project:
  @echo "Updating Xcode project dependencies..."
  xcodebuild -resolvePackageDependencies  # TODO: Apparently this might not do anything
