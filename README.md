# outil

[![Package Version](https://img.shields.io/hexpm/v/outil)](https://hex.pm/packages/outil)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/outil/)

A library for writing command line tools. Like so:

```gleam
import gleam/erlang
import gleam/io
import outil

fn say_hello() -> Command(Nil) {
  use cmd <- outil.command("hello", "Say hello to someone")
  use name, cmd <- outil.string_arg(cmd, "name")
  use enthusiasm, cmd <- outil.int_opt(cmd, "enthusiasm", "How enthusiastic?", 1)

  outil.implement(
    cmd,
    fn(argv) {
      try name = name(argv)
      try enthusiasm = enthusiasm(argv)

      let message = "Hello, " <> name <> string.repeat("!", enthusiasm)

      Ok(io.println(message))
    },
  )
}

fn main() {
  outil.execute(say_hello(), erlang.start_arguments())
}
```

If you don't fancy this style of programming, check out [glint] or [Awesome Gleam] for alternatives.

[glint]: https://github.com/tanklesxl/glint
[Awesome Gleam]: https://github.com/gleam-lang/awesome-gleam#cli

## Quick start

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```

## Installation

If available on Hex this package can be added to your Gleam project:

```sh
gleam add outil
```

and its documentation can be found at <https://hexdocs.pm/outil>.
