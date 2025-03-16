_default:
  @just --list

lint:
  @echo "Linting Swift files..."
  swiftformat --lint .

format:
  @echo "Formatting Swift files..."
  swiftformat .
