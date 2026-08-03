# Engineering Design Assistant

Engineering Design Assistant captures engineering requirements and checks
units and constraints. It stores a typed design brief in a local SQLite
database. The brief can move between the Flutter app, the command-line tool,
and an MCP server.

## Features

- Capture requirements, constraints, assumptions, and notes
- Validate units and design constraints
- Import and export a JSON design brief
- Load a sample linear-actuator brief
- Convert compatible engineering units
- Expose the brief through an MCP server over standard input and output

## Requirements

- Flutter with Dart 3.12 or later

The application uses Flutter, `sqflite_common_ffi`, and the Dart MCP package.
The database is local to the machine.

## Setup

Install the dependencies from the repository root:

```text
flutter pub get
```

Run the test suite:

```text
flutter test
```

## Flutter app

Start the desktop application with:

```text
flutter run -d windows
```

Select another device when you use a different Flutter target.

## Command-line tool

The `eda` command uses a local database by default. You can pass `--db PATH` to
use another database.

Initialize an empty database:

```text
dart run bin/eda.dart init
```

Load sample data and validate it:

```text
dart run bin/eda.dart sample
dart run bin/eda.dart validate
```

Export or import a JSON handoff:

```text
dart run bin/eda.dart export --out brief.json
dart run bin/eda.dart import --in brief.json
```

Convert a value between compatible units:

```text
dart run bin/eda.dart units "25 mm" "in"
```

## MCP server

Run the MCP server over standard input and output:

```text
dart run bin/eda_mcp_server.dart
```

Pass `--db PATH` to select the database. Configure the command in an MCP
client that can start local stdio servers.

## Project layout

- `lib/` - Flutter UI and application code
- `bin/eda.dart` - command-line interface
- `bin/eda_mcp_server.dart` - standalone MCP entry point
- `test/` - automated tests

## Limitations

This project is an early EngineerKit component. It does not replace engineering
review, approved standards, or professional design software.

## License

No license file is published yet. Treat this repository as an experimental
project until a license is added.
