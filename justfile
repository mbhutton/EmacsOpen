_default:
  @just --list

lint:
  @echo "Linting Swift files..."
  swift-format lint --strict --recursive .

format:
  @echo "Formatting Swift files..."
  swift-format format --in-place --recursive .

clean:
  @echo "Cleaning build artifacts..."
  rm -rf .DerivedData/
  rm -rf .build/
  rm -rf .swiftpm/

build-cli:
  @echo "Building CLI..."
  # Note: define -warning-as-errors here, not in Package.swift, because Xcode will always pass the
  # incompatible -suppress-warnings flag when building the library automatically from the Xcode GUI.
  swift build --configuration release --product emacsopen -Xswiftc -warnings-as-errors

build-app:
  @echo "Building App using Xcode..."
  # Build the app using xcodebuild
  xcodebuild \
    -project EmacsOpen.xcodeproj -scheme EmacsOpen \
    -derivedDataPath ./.DerivedData \
    -configuration Release \
    -quiet \
    clean \
    build

build: build-cli build-app
  @echo "All builds completed"

run:
  open .DerivedData/Build/Products/Release/EmacsOpen.app

update-swiftpm:
  @echo "Updating SwiftPM dependencies..."
  rm -f Package.resolved
  swift package update

update-xcode-project:
  @echo "Updating Xcode project dependencies..."
  xcodebuild -resolvePackageDependencies  # TODO: Apparently this might not do anything
