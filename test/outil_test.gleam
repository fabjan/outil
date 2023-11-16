import gleam/option.{Some}
import gleam/string
import gleeunit
import gleeunit/should
import outil.{type CommandResult, CommandError, CommandLineError, Help, command}
import outil/error.{MalformedArgument, MissingArgument}
import outil/arg
import outil/opt

pub fn main() {
  gleeunit.main()
}

fn hello_cmd(args: List(String)) -> CommandResult(String, Nil) {
  use cmd <- command("hello", "Say hello to someone.", args)
  use name, cmd <- arg.string(cmd, "name")

  use enthusiasm, cmd <- opt.int(cmd, "enthusiasm", "How enthusiastic?", 1)
  use loudly, cmd <- opt.bool(cmd, "loudly", "Use all caps.")
  use name <- name(cmd)
  use enthusiasm <- enthusiasm(cmd)
  use loudly <- loudly(cmd)

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
  use waldo, cmd <- opt.bool_(cmd, "waldo", Some("w"), "invert quux?")
  use fred, cmd <- opt.float_(cmd, "fred", Some("f"), "multiply corge", 10.0)
  use plugh, cmd <- opt.int_(cmd, "plugh", Some("p"), "add to grault", 1)
  use xyzzy, cmd <- opt.string_(cmd, "xyzzy", Some("x"), "garply suffix", "!")

  use foo <- foo(cmd)
  use bar <- bar(cmd)
  use baz <- baz(cmd)
  use qux <- qux(cmd)

  use quux <- quux(cmd)
  use corge <- corge(cmd)
  use grault <- grault(cmd)
  use garply <- garply(cmd)

  use waldo <- waldo(cmd)
  use fred <- fred(cmd)
  use plugh <- plugh(cmd)
  use xyzzy <- xyzzy(cmd)

  Ok(FruitBasket(
    foo,
    bar,
    baz,
    qux,
    quux && !waldo,
    corge *. fred,
    grault + plugh,
    garply <> xyzzy,
  ))
}

fn twoface_cmd(args: List(String)) -> CommandResult(String, String) {
  use cmd <- command("twoface", "Flip a coin.", args)
  use heads, cmd <- opt.bool(cmd, "heads", "Heads?")
  use tails, cmd <- opt.bool(cmd, "tails", "Tails?")

  use heads <- heads(cmd)
  use tails <- tails(cmd)

  case #(heads, tails) {
    #(True, False) -> Ok("Heads!")
    #(False, True) -> Ok("Tails!")
    _ -> Error(CommandError("You must choose heads or tails."))
  }
}

// verify that the help text works even if there are no positional arguments
fn help_opt_cmd(args: List(String)) -> CommandResult(String, Nil) {
  use cmd <- command("help", "Test help text.", args)
  use foo, cmd <- opt.string(cmd, "foo", "bar", "baz")

  use x <- foo(cmd)

  Ok(x)
}

pub fn help_opt_test() {
  let expect_help_usage =
    "help -- Test help text.

Usage: help

Options:
  --foo  bar (string, default: \"baz\")
  -h, --help  Show this help text and exit."

  help_opt_cmd([])
  |> should.equal(Ok("baz"))

  help_opt_cmd(["--help"])
  |> should.equal(Error(Help(expect_help_usage)))
}

pub fn command_error_usage_test() {
  let expect_usage =
    "hello -- ERROR! Missing argument for option: name

Usage: hello <name>

Options:
  --enthusiasm  How enthusiastic? (int, default: 1)
  --loudly  Use all caps. (bool, default: false)
  -h, --help  Show this help text and exit."

  let assert Error(CommandLineError(_, usage)) = hello_cmd([])

  usage
  |> should.equal(expect_usage)
}

pub fn help_test() {
  let expect_usage =
    "hello -- Say hello to someone.

Usage: hello <name>

Options:
  --enthusiasm  How enthusiastic? (int, default: 1)
  --loudly  Use all caps. (bool, default: false)
  -h, --help  Show this help text and exit."

  hello_cmd(["--help"])
  |> should.equal(Error(Help(expect_usage)))
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
  let assert Error(CommandLineError(reason, _)) = hello_cmd([])

  reason
  |> should.equal(MissingArgument("name"))
}

pub fn malformed_argument_test() {
  let argv = ["world", "--enthusiasm=three"]
  let result = hello_cmd(argv)

  let assert Error(CommandLineError(reason, _)) = result

  reason
  |> should.equal(MalformedArgument("enthusiasm", "three"))
}

pub fn all_the_things_test() {
  let argv = [
    "true", "1.0", "1", "hello", "--quux", "--corge=2.0", "--grault=2",
    "--garply=world", "-w", "-f=2.0", "-p=3", "-x=!",
  ]
  let result = the_whole_fruit_basket_cmd(argv)

  result
  |> should.equal(Ok(FruitBasket(True, 1.0, 1, "hello", False, 4.0, 5, "world!")))
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
