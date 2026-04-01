<p align="center">
  <img src="assets/heather-logo.png" alt="heather Logo" width="300">
</p>

<p align="center">
  <strong>A fast, cross-platform Pascal Script engine for task automation.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/FPC-3.2.2-purple.svg?style=flat-square" alt="Free Pascal Compiler">
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg?style=flat-square" alt="Cross Platform">
  <img src="https://img.shields.io/badge/License-BSD--3--Clause-blue.svg?style=flat-square" alt="License">
</p>

<p align="center">
  <a href="https://GitHub.com/urban233/HEATHER/graphs/commit-activity"><img src="https://img.shields.io/badge/Maintained%3F-yes-blue.svg?style=flat-square" alt="Maintenance"></a>
  <a href="https://github.com/urban233/HEATHER/releases/"><img src="https://img.shields.io/github/release/urban233/HEATHER.svg?style=flat-square&color=blue" alt="Latest Release"></a>
  <a href="https://github.com/urban233/HEATHER/issues"><img src="https://img.shields.io/github/issues/urban233/HEATHER?style=flat-square" alt="Issues"></a>
  <a href="https://gitHub.com/urban233/HEATHER/graphs/contributors/"><img src="https://img.shields.io/github/contributors/urban233/HEATHER.svg?style=flat-square&color=blue" alt="Contributors"></a>
</p>

---

## 🚀 Overview

**HEATHER** (**H**igh-performance **E**xecutable **A**utomation **T**oolkit for **H**ost **E**nvironments & **R**untime) is a native, zero-dependency command-line utility for executing Pascal scripts. Built on top of the robust Free Pascal Compiler (FPC) and utilizing Lazarus Pascal Script component under the hood, it delivers a powerful scripting environment without the bloat of heavy runtime environments like Python or Node.js.

Whether you need to batch process files, orchestrate complex build pipelines, or manage system operations, HEATHER handles it instantly with native performance.

## ✨ Features

- **Native Execution:** Compiles and runs Pascal scripts on the fly with native speed.
- **Rich Standard Library:** Includes a baked-in standard library (`THeatherStdLib`) that provides Python-parity functions for:
  - Process Execution (replacing `subprocess`)
  - File & Tree Operations (replacing `shutil` and `os`)
  - Path Manipulation (replacing `os.path`)
  - Environment & Context management
- **Zero Dependencies:** A single, lightweight executable. No Python environments, no Node modules, no `.NET` runtimes required.
- **Cross-Platform:** Write once, compile anywhere. Runs natively on Windows, macOS, and Linux.

---

## 📦 Installation

### Build from Source
Building HEATHER is incredibly straightforward. The project uses a custom compiler configuration (`heather.cfg`) to ensure a pristine source tree, outputting all build artifacts safely to `bin/` and `obj/` folders.

Ensure you have the [Free Pascal Compiler](https://www.freepascal.org/) and [Lazarus](https://www.lazarus-ide.org/) (for the Pascal Script component) installed, then clone the repository:

```bash
git clone https://github.com/urban233/HEATHER.git
cd HEATHER
```

**For Windows:**
Use the included batch script to compile the project.

```cmd
.\build.bat build
```

*The compiled executable will be located at `bin\heather.exe`.*

*(To clean your build environment, run `.\build.bat clean`).*

**For macOS & Linux**
Use the included Makefile to compile the project.

```bash
make
```

```bash
sudo make install
```

*The compiled executable will be located at `bin\heather`.*

*(To clean your build environment, run `make clean`).*

---

## 📖 Usage

HEATHER is built to execute `.pas` scripts that automate your tasks.

### Executing a Script

To run a script, simply pass it as an argument to the HEATHER executable:

```bash
bin/heather.exe your_script.pas
```

### Example Script

Here is an example of what a HEATHER script looks like:

```pascal
program build_automation;

var
  Cwd: string;
  OutputText: string;
begin
  Print('--- Build Automation Started ---');
  
  Cwd := GetCwd();
  Print('Working Directory: ' + Cwd);
  
  Print('Cleaning old build...');
  RemoveDirTree('dist');
  MakeDirs('dist/bin');
  
  Print('Compiling project...');
  OutputText := ExecOut('fpc @myconfig.cfg src/main.pas');
  Print(OutputText);
  
  if FileExists('src/main.exe') then
  begin
    CopyFile('src/main.exe', 'dist/bin/main.exe', True);
    Print('Build successful!');
  end
  else
  begin
    Print('Build failed!');
    Terminate(1);
  end;
end.
```

### Standard Library Functions

Your scripts have access to the following built-in functions:

**Console:**
- `procedure Print(const Msg: string);`

**Process Execution:**
- `function Exec(const Command: string): Integer;`
- `function ExecOut(const Command: string): string;`

**File & Directory Operations:**
- `function CopyFile(const Source, Dest: string; Overwrite: Boolean): Boolean;`
- `function CopyDir(const Source, Dest: string): Boolean;`
- `function RemoveDirTree(const Path: string): Boolean;`
- `function MakeDirs(const Path: string): Boolean;`

**Path Manipulation:**
- `function JoinPath(const Path1, Path2: string): string;`
- `function FileExists(const Path: string): Boolean;`
- `function DirExists(const Path: string): Boolean;`
- `function GetFileName(const Path: string): string;`
- `function GetFileExt(const Path: string): string;`

**Environment & Context:**
- `function GetEnv(const Name: string): string;`
- `function SetEnv(const Name, Value: string): Boolean;`
- `function GetCwd: string;`
- `function SetCwd(const Path: string): Boolean;`
- `procedure Terminate(ExitCode: Integer);`

---

## 🔮 Future Ideas

Here are some ideas for future enhancements to HEATHER:

- **Network Operations:** Add functions for downloading files (e.g., `DownloadFile(URL, Dest)`), making HTTP requests, and interacting with REST APIs.
- **Archive Support:** Built-in functions to extract ZIP/TAR archives (`ExtractZip(Source, Dest)`) and create archives to easily package build artifacts.
- **JSON Parsing:** Native support for parsing and modifying JSON files to easily read package manifests or configuration files.
- **Hash Verification:** Functions to calculate MD5/SHA256 hashes of files to verify downloads or track file changes.
- **Interactive Prompts:** Add a function to ask for user input during script execution (`PromptUser(Question)`).
- **String Manipulation:** Expand the standard library with regex matching and advanced string formatting tools.
- **Plugin System:** Allow loading external dynamic libraries (.dll/.so) to extend the script engine's capabilities without recompiling HEATHER.

---

## 🛠️ Architecture

HEATHER is built using modern Object Pascal conventions and a professional build pipeline:

  * **`TPSScript`**: The core Lazarus component that compiles and executes the Pascal scripts on the fly.
  * **`uHeatherLib`**: A modular unit encapsulating all native system calls using modern FPC features like `TProcess` for safe, pipe-based command execution.
  * **`heather.cfg`**: A custom compiler configuration file that enforces strict `-O3` and `-XX` (Smart Linking) optimizations, stripping debug symbols (`-Xs`) to generate the smallest, fastest binary possible.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to check out the issues page. If you want to add new functions to the standard library, please ensure your code follows the existing unit structure in `uHeatherLib.pas` and register them in `heather.pas`.

## 📄 License

This project is licensed under the BSD-3-Clause License - see the [LICENSE](LICENSE) file for details.

### Acknowledgments
This software is made using **RemObjects Pascal Script**, originally created by Carlo Kok and RemObjects Software, LLC.
The Pascal Script component is included under `vendor/PascalScript` and its original license can be found at `vendor/PascalScript/LICENSE.md`.
More information about RemObjects Pascal Script can be found at [RemObjects Software](https://www.remobjects.com).

---

<p align="center">
<i>Built with ❤️ and Free Pascal.</i>
</p>