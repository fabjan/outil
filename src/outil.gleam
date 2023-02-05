import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import outil/core.{ArgvFunction, Command, Error, NotImplemented, Opt}

/// Create a command with the given name and description, and pass it to the
/// given continuation function for further configuration.
///
/// The command gets a default implementation that returns an error.
pub fn command(
  name: String,
  description: String,
  continue: fn(Command(a)) -> Command(a),
) -> Command(a) {
  continue(Command(
    name,
    description,
    [],
    [],
    fn(_) { Error(NotImplemented(name)) },
  ))
}

/// Add the code to evaluate when the command is executed.
pub fn implement(cmd: Command(a), run: ArgvFunction(a)) -> Command(a) {
  Command(cmd.name, cmd.description, cmd.arguments, cmd.options, run)
}

/// Execute the command with the given argument vector.
pub fn execute(cmd: Command(a), args: List(String)) -> Result(a, Error) {
  cmd.run(args)
}

/// Return a string describing the usage of the given command.
pub fn usage(cmd: Command(a)) -> String {
  let args =
    cmd.arguments
    |> list.map(fn(arg) { arg.name })
    |> list.map(fn(arg) { "<" <> arg <> ">" })
    |> string.join(" ")

  let opts =
    cmd.options
    |> list.map(fn(opt) {
      let Opt(long, short, desc, value) = opt
      let short = option.map(short, fn(s) { "-" <> s <> ", " })
      let short = option.unwrap(short, "")
      let long = "--" <> long
      let typ = opt_type(value)
      let default = show_default(value)
      let meta = "(" <> typ <> ", default: " <> default <> ")"

      short <> long <> "  " <> desc <> " " <> meta
    })
    |> list.map(fn(opt) { "  " <> opt })
    |> string.join("\n")

  let opts = "Options:\n" <> opts <> "\n"

  cmd.description <> "\n\n" <> "Usage: " <> cmd.name <> " " <> args <> "\n\n" <> opts
}

fn opt_type(value: core.OptValue) -> String {
  case value {
    core.BoolOpt -> "bool"
    core.FloatOpt(_) -> "float"
    core.IntOpt(_) -> "int"
    core.StringOpt(_) -> "string"
  }
}

fn show_default(value: core.OptValue) {
  case value {
    core.BoolOpt -> "false"
    core.FloatOpt(default) -> float.to_string(default)
    core.IntOpt(default) -> int.to_string(default)
    core.StringOpt(default) -> "\"" <> default <> "\""
  }
}
