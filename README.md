# outil

[![Package Version](https://img.shields.io/hexpm/v/outil)](https://hex.pm/packages/outil)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/outil/)

A library for writing command line tools. Like so:

```gleam
import gleam/erlang
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import outil.{command, print_usage_and_exit}
import outil/arg
import outil/opt

fn say_hello(args) {
  use cmd <- command("hello", "Say hello to someone", args)
  use name, cmd <- arg.string(cmd, "name")
  use enthusiasm, cmd <- opt.int(cmd, "enthusiasm", "How enthusiastic?", 1)

  use name <- name(cmd)
  use enthusiasm <- enthusiasm(cmd)

  let message = "Hello, " <> name <> string.repeat("!", enthusiasm)

  Ok(io.println(message))
}

pub fn main() {
  // Erlang is not required, this example just uses it for getting ARGV
  let args = erlang.start_arguments()

  say_hello(args)
  |> result.map_error(print_usage_and_exit)
}
```

If you don't fancy this style of programming, check out [glint] or [Awesome Gleam] for alternatives.

Outil is not going to have many cool features for building comprehensive command line
interfaces. It is meant to fit simple programs with simple needs.

[glint]: https://github.com/tanklesxl/glint
[Awesome Gleam]: https://github.com/gleam-lang/awesome-gleam#cli

## Quick start

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```

## Installation

Outil is available on Hex and can be added to your Gleam project like so:

```sh
gleam add outil
```

and its documentation can be found at <https://hexdocs.pm/outil>.

## Changelog

### 0.5.0

* Adapted for Gleam 0.32.

### 0.4.0

* Adapted to Gleam 0.27, so no more try syntax.
* BREAKING -- API change to let library users use use without result.then wrapping.

### 0.3.3

* Made `--help` show itself in the output.
* Made the usage text present the command line error that caused it to be shown.

### 0.3.2

* Fixed a bug where the automatic `--help` flag didn't react unless the command had positional arguments.

### 0.3.1

* Added convenience helpers print_usage and print_usage_and_exit for handling command errors.

### 0.3.0

* Expanded the return type of commands to include a way for the command code itself to return errors.
* **BREAKING** Some types were renamed to support the above, and be more clear.

### 0.2.1

* Fixed some docs.

### 0.2.0

* **BREAKING** Simplified command implementation. The function is the command now, it no longer returns a `Command` value.

### 0.1.0

* Hello world!
* Something kind of working.
