# Lumix Build System

**Version:** 1.0  
**Language:** Luma

## Overview

Lumix is a build system for the Luma programming language that automates dependency detection, module compilation, and linking. It scans your project directory for `.lx` files, analyzes their dependencies, and generates the appropriate compilation commands.

## Features

- **Automatic Entry Point Detection** - Finds the file containing `pub const main -> fn ()` automatically
- **Dependency Scanning** - Parses `@use` directives to identify module dependencies
- **Deduplication** - Ensures each dependency is only included once in the build command
- **Standard Library Support** - Automatically converts `std_*` module names to `std/*.lx` paths
- **Interactive CLI** - Simple command-based interface for building, cleaning, and inspecting dependencies

## Installation

Compile Lumix with the following command:

```bash
luma src/lumix.lx -name lumix -l src/utility.lx src/parser.lx src/file_system.lx src/module.lx src/user_input.lx std/io.lx std/sys.lx std/vector.lx std/string.lx std/memory.lx
```

This creates the `lumix` executable in your current directory.

## Usage

### Basic Workflow

1. Navigate to your Luma project directory
2. Run `./lumix`
3. Choose a command:
   - `build` - Compile your project
   - `clean` - Remove build artifacts
   - `deps` - Show dependency tree

### Build Command

```
Command (build/clean/deps): build
```

The build process:
1. **Scans** for `.lx` files in the current directory
2. **Auto-detects** the entry point (file with `pub const main -> fn ()`)
3. **Prompts** for output binary name (defaults to `main`)
4. **Compiles** all modules with proper dependency linking

**Example:**
```
=== Building Luma Project ===
Scanning for entry point...
Auto-detected entry point: game.lx

Output binary name (press Enter for 'main'): my_game

Found files:
  - game.lx
  - player.lx
  - renderer.lx

Compiling modules...
Executing command:
luma game.lx -l std/io.lx std/string.lx player.lx renderer.lx -name my_game

Build completed successfully. Output: my_game
```

### Clean Command

Removes build artifacts:
- `*.o` object files
- Default `main` executable
- Temporary files in `/tmp/luma_*.txt`

```
Command (build/clean/deps): clean

=== Cleaning Build Artifacts ===
Done.
```

### Deps Command

Shows the dependency tree for your project:

```
Command (build/clean/deps): deps

=== Dependency Tree ===

Module dependencies:

  game depends on:
    - player
    - renderer
    - std_io

  player depends on:
    - std_string
    - std_memory

  renderer (no dependencies)
```

## How It Works

### 1. File Discovery

Lumix uses the `find` command to locate all `.lx` files:

```bash
find . -name '*.lx' -type f 2>/dev/null > /tmp/luma_files.txt
```

Falls back to `ls` if `find` is unavailable.

### 2. Entry Point Detection

Scans each file for the pattern:
```luma
pub const main -> fn ()
```

The first file containing this pattern becomes the entry point.

### 3. Dependency Parsing

For each file, Lumix:
- Reads the file content
- Finds all `@use` directives
- Extracts module names from quotes: `@use "module_name"`
- Ignores comments (`//`)

### 4. Module Name Conversion

Standard library modules are converted:
- `std_io` → `std/io.lx`
- `std_string` → `std/string.lx`
- `std_memory` → `std/memory.lx`

### 5. Build Command Generation

Lumix constructs a command like:
```bash
luma <entry_point> -l <std_libs> <other_files> -name <output_name>
```

With deduplication to ensure each dependency appears only once.

### 6. Deduplication Strategy

The `has_dep()` function checks if a dependency is already in the build command:

```luma
const has_dep -> fn (slice_ptr: *Slice, slice_count: int, dep_path: *byte) int {
    loop [i: int = 0](i < slice_count) : (i = i + 1) {
        if (string::strcmp(slice_ptr[i].ptr, dep_path) == 0) return 1;
    }
    return 0;
}
```

This prevents duplicate inclusions while keeping the implementation simple.

## Architecture

### Module Breakdown

- **`lumix.lx`** - Main entry point, CLI, and build orchestration
- **`file_system.lx`** - File discovery and directory operations
- **`parser.lx`** - Parsing `@use` directives and file content
- **`module.lx`** - Module name extraction from file paths
- **`utility.lx`** - Helper functions (string ops, file checks, main detection)
- **`user_input.lx`** - Helper function (get_user_input)

### Global State

Dependency graph stored in global arrays:
- `g_module_names` - Module names extracted from files
- `g_file_paths` - Full paths to source files
- `g_dependencies` - List of dependencies for each file
- `g_dep_counts` - Number of dependencies per file
- `g_visited` / `g_in_stack` - For future cycle detection

## Limitations

- **Maximum 500 files** per project (`fs::MAX_FILES`)
- **Maximum 200 dependencies** per file (`parser::MAX_DEPS`)
- **No circular dependency detection** (currently unused but infrastructure exists)
- **Simple deduplication** - relies on string matching, no version resolution
- **Local files only** - no remote package management (yet)

## Configuration

The `BuildConfig` struct defines build settings:

```luma
const BuildConfig -> struct {
    entry_point: *byte,    // Path to main file
    output_name: *byte,    // Binary name
    stdlib_path: *byte,    // Path to std lib (default: "std")
    optimize: int,         // Optimization level (unused)
    debug_symbols: int,    // Debug symbols flag (unused)
    verbose: int           // Verbose output (1 = on)
};
```

Currently, only `entry_point`, `output_name`, and `verbose` are used.

## Troubleshooting

### "No .lx files found"
- Ensure you're in a directory with `.lx` files
- Check file permissions

### "No entry point auto-detected"
- Make sure one file has `pub const main -> fn ()`
- Check for typos in the function signature

### "Could not extract module name"
- Files must have `.lx` extension
- Filenames should be valid identifiers

### Build fails with missing dependencies
- Ensure all imported modules exist as files
- Check that standard library is in the `std/` directory or accessible to the compiler (which if you install it using the install.sh everything should be setup for luma)

## Future Enhancements

See `TODO.md` for planned features and improvements.
