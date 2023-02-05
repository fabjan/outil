import gleam/string
import gleeunit
import gleeunit/should
import outil.{command, execute, implement, usage}
import outil/core.{Command, MalformedArgument, MissingArgument}
import outil/arg
import outil/opt

pub fn main() {
  gleeunit.main()
}

fn hello_cmd() -> Command(String) {
  use cmd <- command("hello", "Say hello to someone")
  use name, cmd <- arg.string(cmd, "name")
  use enthusiasm, cmd <- opt.int(cmd, "enthusiasm", "How enthusiastic?", 1)
  use loudly, cmd <- opt.bool(cmd, "loudly", "Use all caps.")

  implement(
    cmd,
    fn(args) {
      try name = name(args)
      try enthusiasm = enthusiasm(args)
      try loudly = loudly(args)

      let message = "Hello, " <> name <> string.repeat("!", enthusiasm)

      let message = case loudly {
        True -> string.uppercase(message)
        False -> message
      }

      Ok(message)
    },
  )
}

type FruitBasket {
  FruitBasket(
    foo: Bool,
    bar: Float,
    baz: Int,
    qux: String,
    quux: Bool,
    corge: Float,
    grault: Int,
    garply: String,
  )
}

fn the_whole_fruit_basket_cmd() -> Command(FruitBasket) {
  use cmd <- command("basket", "Use all the things!")

  use foo, cmd <- arg.bool(cmd, "foo")
  use bar, cmd <- arg.float(cmd, "bar")
  use baz, cmd <- arg.int(cmd, "baz")
  use qux, cmd <- arg.string(cmd, "qux")

  use quux, cmd <- opt.bool(cmd, "quux", "include quux?")
  use corge, cmd <- opt.float(cmd, "corge", "how much corge?", 1.0)
  use grault, cmd <- opt.int(cmd, "grault", "how many grault?", 1)
  use garply, cmd <- opt.string(cmd, "garply", "which garply?", "default")

  implement(
    cmd,
    fn(args) {
      try foo = foo(args)
      try bar = bar(args)
      try baz = baz(args)
      try qux = qux(args)

      try quux = quux(args)
      try corge = corge(args)
      try grault = grault(args)
      try garply = garply(args)

      Ok(FruitBasket(foo, bar, baz, qux, quux, corge, grault, garply))
    },
  )
}

pub fn command_usage_test() {
  let command = hello_cmd()

  usage(command)
  |> should.equal(
    "Say hello to someone

Usage: hello <name>

Options:
  --enthusiasm  How enthusiastic? (int, default: 1)
  --loudly  Use all caps. (bool, default: false)
",
  )
}

pub fn execute_command_test() {
  let argv = ["world"]
  let command = hello_cmd()

  execute(command, argv)
  |> should.equal(Ok("Hello, world!"))
}

pub fn bool_opt_test() {
  let argv = ["world", "--loudly"]
  let command = hello_cmd()

  execute(command, argv)
  |> should.equal(Ok("HELLO, WORLD!"))
}

pub fn int_opt_test() {
  let argv = ["world", "--enthusiasm=3"]
  let command = hello_cmd()

  execute(command, argv)
  |> should.equal(Ok("Hello, world!!!"))
}

pub fn missing_argument_test() {
  let argv = []
  let command = hello_cmd()

  execute(command, argv)
  |> should.equal(Error(MissingArgument("name")))
}

pub fn malformed_argument_test() {
  let argv = ["world", "--enthusiasm=three"]
  let command = hello_cmd()

  execute(command, argv)
  |> should.equal(Error(MalformedArgument("enthusiasm", "three")))
}

pub fn all_the_things_test() {
  let argv = [
    "true", "1.0", "1", "hello", "--quux", "--corge=2.0", "--grault=2",
    "--garply=world",
  ]
  let command = the_whole_fruit_basket_cmd()

  execute(command, argv)
  |> should.equal(Ok(FruitBasket(True, 1.0, 1, "hello", True, 2.0, 2, "world")))
}
