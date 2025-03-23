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

install-cli:
  @echo "Installing EmacsOpen CLI..."
  mkdir -p ~/sw/emacsopen
  cp ./.build/arm64-apple-macosx/release/emacsopen ~/sw/emacsopen/emacsopen

install-app:
  @echo "Installing EmacsOpen.app..."
  killall EmacsOpen || true
  cp -R .DerivedData/Build/Products/Release/EmacsOpen.app /Applications/

install: install-cli install-app
  @echo "All installations completed"

run-installed-app:
  @echo "Opening installed EmacsOpen app..."
  open /Applications/EmacsOpen.app

run-installed-cli:
  @echo "Running installed EmacsOpen CLI..."
  ~/sw/emacsopen/emacsopen

update-swiftpm:
  @echo "Updating SwiftPM dependencies..."
  rm -f Package.resolved
  swift package update

update-xcode-project:
  @echo "Updating Xcode project dependencies..."
  xcodebuild -resolvePackageDependencies  # TODO: Apparently this might not do anything
