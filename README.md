# outil

[![Package Version](https://img.shields.io/hexpm/v/outil)](https://hex.pm/packages/outil)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/outil/)

A library for writing command line tools. Like so:

```gleam
import gleam/erlang
import gleam/io
import gleam/list
import outil.{command}
import outil/arg
import outil/opt

fn say_hello(args: List(String)) {
  use cmd <- command("hello", "Say hello to someone", args)
  use name, cmd <- arg.string(cmd, "name")
  use enthusiasm, cmd <- opt.int(cmd, "enthusiasm", "How enthusiastic?", 1)

  try name = name(cmd)
  try enthusiasm = enthusiasm(cmd)

  let message = "Hello, " <> name <> string.repeat("!", enthusiasm)

  Ok(io.println(message))
}

fn main() {
  // Erlang is not required, this example just uses it for getting ARGV
  let args = erlang.start_arguments()
  |> list.drop(1) // drop the program name from the arguments we pass in

  say_hello(args)
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
