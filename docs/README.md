# Lumix Build System

**Version:** 1.10  
**Language:** Luma

## Overview

Lumix is a build system for the Luma programming language that automates dependency detection, module compilation, and linking. It scans your project directory for `.lx` files, analyzes their `@use` directives, and generates the appropriate compilation commands. Lumix can be configured via a `lumix.toml` file in your project root, or driven entirely from the command line.

## Features

- **Automatic Entry Point Detection** — Finds the file containing `pub const main -> fn` automatically
- **Dependency Scanning** — Parses `@use` directives to identify module dependencies
- **Deduplication** — Ensures each dependency is included only once in the build command
- **Standard Library Support** — Automatically converts `std_*` module names to `std/*.lx` paths
- **TOML Configuration** — Project settings can be stored in `lumix.toml`
- **Interactive CLI** — Simple command-based interface for building, cleaning, and inspecting dependencies
- **Colored Output** — Uses terminal colors to highlight commands and dependency trees

## Installation

Compile Lumix with the following command:

```bash
luma src/lumix.lx -l std/string.lx std/memory.lx std/io.lx src/file_system.lx src/getch.lx src/parser.lx src/toml.lx src/user_input.lx src/utility.lx std/termfx.lx std/sys.lx src/module.lx --no-sanitize -O3 -name bin/lumix -O0
```

This creates the `lumix` executable at `bin/lumix`.

## Usage

### Basic Workflow

1. Navigate to your Luma project directory
2. Run `./lumix <command>`

### Commands

| Command | Description |
|---------|-------------|
| `build [output_name]` | Compile your project |
| `clean` | Remove build artifacts |
| `config` | Show resolved TOML configuration |
| `deps` | Show dependency tree |
| `init` | Scaffold a new `lumix.toml` |
| `run` | Build and execute the project binary |
| `version` | Print the current Lumix version |

---

### Build Command

```
./lumix build [output_name]
```

The output name can be supplied as the first argument after `build`. If omitted, Lumix falls back to the `name` field in `lumix.toml`. If neither is present, the build will fail with an error.

The build process:

1. **Loads** `lumix.toml` if one is present in the current directory
2. **Resolves the entry point** — TOML `entry` field takes priority, then auto-detection (scans for `pub const main -> fn`), then a manual prompt
3. **Resolves the scan directory** — TOML `directory` field, defaulting to `.`
4. **Resolves the binary output directory** — TOML `binary_dir` field (optional)
5. **Resolves build flags** — TOML `build_flags` field (optional)
6. **Resolves dependency paths** — `[dependencies].paths` entries ending in `.lx` are treated as files; entries without `.lx` are scanned as directories for all `.lx` files
7. **Builds the dependency graph** by scanning all `.lx` files in the scan directory
8. **Constructs and executes** the `luma` compile command, including all resolved dependency files

**Example output:**

```
lumix.toml found — using config file.

=== Building Luma Project ===
Entry point: src/game.lx
Output name: my_game
Executing command:
luma src/game.lx -l std/io.lx std/string.lx src/player.lx src/renderer.lx --no-sanitize -O3 -name bin/my_game

Build completed successfully. Output: my_game
```

---

### Clean Command

```
./lumix clean
```

Prompts for confirmation (y/n), then removes:

- `obj/` directory
- `main` executable
- Temporary files matching `/tmp/luma_*.txt`

---

### Deps Command

```
./lumix deps
```

Scans the current directory and prints a colored dependency tree:

```
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

---

### Version Command

```
./lumix version
```

Prints the current Lumix version string (e.g. `Luma Build System v1.10`).

---

### Init Command

```
./lumix init
```

Scaffolds a new `lumix.toml` in the current directory. If one already exists, prompts for confirmation before overwriting.

---

### Config Command

```
./lumix config
```

Parses and displays the resolved configuration from `lumix.toml`, including all sections and auto-detected values (such as the entry point file).

**Example output:**

```
=== Configuration ===
Config file: lumix.toml

[project]
  name      = "lumix"
  entry     = "src/lumix.lx"
  directory = "src"

[build]
  flags     = "-O3"

[output]
  binary_dir = "bin"

[dependencies]
  paths     = (none)

[run]
  args      = (none)

--- Auto-Detected ---
  entry     = "src/utility.lx"
```

---

### Run Command

```
./lumix run
```

Builds the project and then executes the resulting binary. Uses the same configuration resolution as `build`. If `binary_dir` is set in `lumix.toml`, the binary is launched from that directory. Any arguments specified in the `[run] args` field are passed to the binary at execution time.

---

## lumix.toml Configuration

Lumix automatically reads `lumix.toml` from the current working directory when running `build`. All fields are optional — any field not set falls back to the default behavior described below.

### Full Example

```toml
[project]
name      = "lumix"
directory = "src"
entry     = "src/lumix.lx"

[dependencies]
paths = [
    "libs/sdl2/",
    "lib/audio.lx"
]

[build]
flags = "--no-sanitize -O3"

[output]
binary_dir = "bin"

[run]
args = "--debug --port 8080"
```

### Sections and Fields

#### `[project]`

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `name` | string | Output binary name | Required (or pass as CLI arg) |
| `entry` | string | Path to the entry point `.lx` file | Auto-detected |
| `directory` | string | Directory to scan for `.lx` source files | `.` (current directory) |

#### `[dependencies]`
| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `paths` | array of strings | Extra source files or directories to include. Paths ending in `.lx` are added as files; all others are scanned recursively for `.lx` files (e.g. `"libs/sdl2/"` includes every `.lx` under `libs/sdl2/`) | *(none)* |

#### `[build]`

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `flags` | string | Extra flags passed to the `luma` compiler (e.g. `--no-sanitize -O3`) | *(none)* |

#### `[output]`

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `binary_dir` | string | Directory to place the compiled binary in | *(none — binary placed in current dir)* |

#### `[run]`

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `args` | string | Arguments passed to the binary when using `run` | *(none)* |

### Priority Rules

When both `lumix.toml` and command-line arguments are present, the following priority order applies:

- **Output name:** CLI argument (`./lumix build myapp`) > `[project] name`
- **Entry point:** `[project] entry` > auto-detection > interactive prompt
- **Scan directory:** `[project] directory` > `.`
- **Binary directory:** `[output] binary_dir` > current directory
- **Build flags:** `[build] flags` > *(none)*
- **Dependency paths:** `[dependencies] paths` — appended as extra source files; directories expanded to all `.lx` files
- **Run arguments:** `[run] args` — passed to the binary when executing `run`

### Comments

TOML comments use `#`:

```toml
# This is a comment
[project]
name = "myapp"  # inline comments are also supported
```

---

## How It Works

### 1. File Discovery

Lumix uses `find` to locate all `.lx` files under the configured scan path:

```bash
find <path> -name '*.lx' -type f 2>/dev/null > /tmp/luma_files.txt
```

Falls back to `ls` if `find` is unavailable.

### 2. Entry Point Detection

Scans each file for the pattern:

```luma
pub const main -> fn
```

The first file containing this pattern becomes the entry point.

### 3. Dependency Parsing

For each file, Lumix reads the content, finds all `@use` directives at line starts (ignoring `//` comments), and extracts the module name from the quoted string:

```luma
@use "module_name" as alias
```

### 4. Module Name Conversion

Standard library modules are converted automatically:

- `std_io` → `std/io.lx`
- `std_string` → `std/string.lx`
- `std_memory` → `std/memory.lx`
- `std_termfx` → `std/termfx.lx`
- *(etc.)*

### 5. Build Command Generation

Lumix constructs a command of the form:

```bash
luma <entry_point> -l <std_libs> <other_files> <dep_paths> [build_flags] -name <binary_dir/output_name>
```

Dependency paths from `[dependencies].paths` are appended after the scanned source files. Directories are expanded into individual `.lx` files during command construction.

### 6. Deduplication

The `has_dep()` function checks whether a dependency path is already present in the command before adding it, preventing duplicate inclusions via string comparison.

---

## Architecture

### Module Breakdown

| File | Module | Role |
|------|--------|------|
| `lumix.lx` | `build` | Main entry point, CLI dispatcher, build orchestration |
| `file_system.lx` | `file_system` | File discovery and directory operations |
| `parser.lx` | `parse` | Parsing `@use` directives and file path lines |
| `module.lx` | `module` | Module name extraction from file paths |
| `utility.lx` | `utility` | Helper functions (string ops, file existence, main detection) |
| `user_input.lx` | `user_input` | `get_user_input` helper for prompted input with defaults |
| `getch.lx` | `getch` | Single-character terminal input, yes/no prompts |
| `toml.lx` | `toml` | `lumix.toml` parser and `TomlConfig` struct |

### BuildConfig Struct

```luma
const BuildConfig -> struct {
    entry_point:   *byte,   // Path to the entry point file
    output_name:   *byte,   // Binary name
    stdlib_path:   *byte,   // Path to std lib (always "std")
    scan_path:     *byte,   // Directory to scan for .lx files
    binary_dir:    *byte,   // Output directory for the binary (optional)
    run_args:      *byte,   // Arguments for run command (reserved)
    build_flags:   *byte,   // Extra compiler flags from lumix.toml
    optimize:      int,     // Optimization level (reserved)
    debug_symbols: int,     // Debug symbols flag (reserved)
    verbose:       int      // Verbose output (always 1)
};
```

### Global Dependency Graph

The dependency graph is stored in module-level global arrays:

- `g_module_names` — Module names extracted from file paths
- `g_file_paths` — Full paths to source files
- `g_dependencies` — Dependency lists per file (from `@use` directives)
- `g_dep_counts` — Number of dependencies per file
- `g_graph_size` — Number of files in the graph

---

## Limitations

- **Maximum 500 files** per project (`fs::MAX_FILES`)
- **Maximum 200 dependencies** per file (`parser::MAX_DEPS`)
- **No circular dependency detection**
- **Unix only** — `getch` and file discovery use `stty`/`find`/`system()` calls
- **Local files only** — no remote package management

---

## Troubleshooting

**"No .lx files found"**  
Ensure you're in a directory with `.lx` files, or that `[project] directory` in `lumix.toml` points to the right path.

**"No entry point auto-detected"**  
Make sure exactly one file contains `pub const main -> fn`. Check for typos in the signature.

**"No output name provided"**  
Supply a name as a CLI argument (`./lumix build myapp`) or set `name` under `[project]` in `lumix.toml`.

**"Could not extract module name"**  
Files must have a `.lx` extension and a valid filename.

**Build fails with missing dependencies**  
Ensure all imported modules exist as `.lx` files in the scan path, and that the standard library is in the `std/` directory accessible to the compiler. If you installed Luma using `install.sh`, this should be set up automatically.

---

## Future Enhancements

- Incremental builds (only recompile changed files)
- Parallel compilation
- Cross-platform support (Windows/macOS)
- Circular dependency detection
