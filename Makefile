# ==========================================
# heather Makefile (macOS & Linux)
# ==========================================

APP = heather
SRC_FILE = src/heather.pas
BIN_DIR = bin
OBJ_DIR = obj

# Mark these as commands, not physical files
.PHONY: all build clean install

# The default command when you just type 'make'
all: build

build:
	@echo "==> Scaffolding directories..."
	@mkdir -p $(BIN_DIR) $(OBJ_DIR)
	@echo "==> Compiling $(APP)..."
	@fpc @heather.cfg $(SRC_FILE)
	@echo "==> Build complete! Executable is at $(BIN_DIR)/$(APP)"

clean:
	@echo "==> Cleaning build artifacts..."
	@rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
	@echo "==> Clean complete."

install: build
	@echo "==> Installing $(APP) to /usr/local/bin (Requires sudo)..."
	@sudo cp $(BIN_DIR)/$(APP) /usr/local/bin/$(APP)
	@echo "==> Installation complete! You can now type '$(APP)' anywhere."
