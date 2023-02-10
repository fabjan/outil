import gleam/string
import gleeunit
import gleeunit/should
import outil.{CommandError, CommandLineError, CommandResult, Help, command}
import outil/error.{MalformedArgument, MissingArgument}
import outil/arg
import outil/opt

pub fn main() {
  gleeunit.main()
}

const hello_usage = "hello -- Say hello to someone.

Usage: hello <name>

Options:
  --enthusiasm  How enthusiastic? (int, default: 1)
  --loudly  Use all caps. (bool, default: false)"

fn hello_cmd(args: List(String)) -> CommandResult(String, Nil) {
  use cmd <- command("hello", "Say hello to someone.", args)
  use name, cmd <- arg.string(cmd, "name")
  use enthusiasm, cmd <- opt.int(cmd, "enthusiasm", "How enthusiastic?", 1)
  use loudly, cmd <- opt.bool(cmd, "loudly", "Use all caps.")

  try name = name(cmd)
  try enthusiasm = enthusiasm(cmd)
  try loudly = loudly(cmd)

  let message = "Hello, " <> name <> string.repeat("!", enthusiasm)

  let message = case loudly {
    True -> string.uppercase(message)
    False -> message
  }

  Ok(message)
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

fn the_whole_fruit_basket_cmd(
  args: List(String),
) -> CommandResult(FruitBasket, String) {
  use cmd <- command("basket", "Use all the things!", args)

  use foo, cmd <- arg.bool(cmd, "foo")
  use bar, cmd <- arg.float(cmd, "bar")
  use baz, cmd <- arg.int(cmd, "baz")
  use qux, cmd <- arg.string(cmd, "qux")

  use quux, cmd <- opt.bool(cmd, "quux", "include quux?")
  use corge, cmd <- opt.float(cmd, "corge", "how much corge?", 1.0)
  use grault, cmd <- opt.int(cmd, "grault", "how many grault?", 1)
  use garply, cmd <- opt.string(cmd, "garply", "which garply?", "default")

  try foo = foo(cmd)
  try bar = bar(cmd)
  try baz = baz(cmd)
  try qux = qux(cmd)

  try quux = quux(cmd)
  try corge = corge(cmd)
  try grault = grault(cmd)
  try garply = garply(cmd)

  Ok(FruitBasket(foo, bar, baz, qux, quux, corge, grault, garply))
}

fn twoface_cmd(args: List(String)) -> CommandResult(String, String) {
  use cmd <- command("twoface", "Flip a coin.", args)
  use heads, cmd <- opt.bool(cmd, "heads", "Heads?")
  use tails, cmd <- opt.bool(cmd, "tails", "Tails?")

  try heads = heads(cmd)
  try tails = tails(cmd)

  case #(heads, tails) {
    #(True, False) -> Ok("Heads!")
    #(False, True) -> Ok("Tails!")
    _ -> Error(CommandError("You must choose heads or tails."))
  }
}

const help_usage = "help -- Test help text.

Usage: help

Options:
  --foo  bar (string, default: \"baz\")"

fn help_cmd(args: List(String)) -> CommandResult(String, Nil) {
  use cmd <- command("help", "Test help text.", args)
  use foo, cmd <- opt.string(cmd, "foo", "bar", "baz")

  foo(cmd)
}

pub fn help_usage_test() {
  assert Ok("baz") = help_cmd([])

  assert Error(Help(usage)) = help_cmd(["--help"])

  usage
  |> should.equal(help_usage)
}

pub fn command_usage_test() {
  let result = hello_cmd([])

  assert Error(CommandLineError(_, usage)) = result

  usage
  |> should.equal(hello_usage)
}

pub fn help_test() {
  let argv = ["--help"]
  let result = hello_cmd(argv)

  assert Error(Help(usage)) = result

  usage
  |> should.equal(hello_usage)
}

pub fn execute_command_test() {
  let argv = ["world"]
  let result = hello_cmd(argv)

  result
  |> should.equal(Ok("Hello, world!"))
}

pub fn bool_opt_test() {
  let argv = ["world", "--loudly"]
  let result = hello_cmd(argv)

  result
  |> should.equal(Ok("HELLO, WORLD!"))
}

pub fn int_opt_test() {
  let argv = ["world", "--enthusiasm=3"]
  let result = hello_cmd(argv)

  result
  |> should.equal(Ok("Hello, world!!!"))
}

pub fn missing_argument_test() {
  let argv = []
  let result = hello_cmd(argv)

  assert Error(CommandLineError(reason, _)) = result

  reason
  |> should.equal(MissingArgument("name"))
}

pub fn malformed_argument_test() {
  let argv = ["world", "--enthusiasm=three"]
  let result = hello_cmd(argv)

  assert Error(CommandLineError(reason, _)) = result

  reason
  |> should.equal(MalformedArgument("enthusiasm", "three"))
}

pub fn all_the_things_test() {
  let argv = [
    "true", "1.0", "1", "hello", "--quux", "--corge=2.0", "--grault=2",
    "--garply=world",
  ]
  let result = the_whole_fruit_basket_cmd(argv)

  result
  |> should.equal(Ok(FruitBasket(True, 1.0, 1, "hello", True, 2.0, 2, "world")))
}

pub fn command_error_test() {
  twoface_cmd(["--heads"])
  |> should.equal(Ok("Heads!"))

  twoface_cmd(["--tails"])
  |> should.equal(Ok("Tails!"))

  twoface_cmd([])
  |> should.equal(Error(CommandError("You must choose heads or tails.")))

  twoface_cmd(["--heads", "--tails"])
  |> should.equal(Error(CommandError("You must choose heads or tails.")))
}
