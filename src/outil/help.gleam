import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import outil.{
  BoolOpt, Command, CommandLineError, CommandResult, FloatOpt, Help, IntOpt, Opt,
  OptValue, StringOpt,
}
import outil/error.{Reason}

/// A function using the command line arguments which can return command error reasons.
pub type UseArgs(a) =
  fn(List(String)) -> Result(a, Reason)

/// Given a command, if the command line arguments contain `--help` or `-h`
/// then return a help "error" with the usage string.
/// Otherwise, pass the arguments to the given function and if it returns an
/// error, wrap it in a `CommandLineError` with the usage string.
pub fn wrap_usage(cmd: Command, continue: UseArgs(a)) -> CommandResult(a, _) {
  let argv_contains = fn(s) { list.contains(cmd.argv, s) }

  try args = case argv_contains("--help") || argv_contains("-h") {
    True -> Error(Help(usage(cmd)))
    False -> Ok(cmd.argv)
  }

  continue(args)
  |> result.map_error(CommandLineError(_, usage(cmd)))
}

fn usage(cmd: Command) -> String {
  let args =
    cmd.arguments
    |> list.map(fn(arg) { "<" <> arg.name <> ">" })
    |> string.join(" ")

  let args = case args {
    "" -> ""
    _ -> " " <> args
  }
  let usage = "\n\nUsage: " <> cmd.name <> args

  let opts =
    cmd.options
    |> list.map(describe_opt)
    |> list.map(fn(opt) { "  " <> opt })
    |> string.join("\n")

  let opts = case opts {
    "" -> ""
    _ -> "\n\nOptions:\n" <> opts
  }

  cmd.name <> " -- " <> cmd.description <> usage <> opts
}

fn describe_opt(opt: Opt) {
  let Opt(long, short, desc, value) = opt
  let short = option.map(short, fn(s) { "-" <> s <> ", " })
  let short = option.unwrap(short, "")
  let long = "--" <> long
  let typ = opt_type(value)
  let default = show_default(value)
  let meta = "(" <> typ <> ", default: " <> default <> ")"

  short <> long <> "  " <> desc <> " " <> meta
}

fn opt_type(value: OptValue) -> String {
  case value {
    BoolOpt -> "bool"
    FloatOpt(_) -> "float"
    IntOpt(_) -> "int"
    StringOpt(_) -> "string"
  }
}

fn show_default(value: OptValue) {
  case value {
    BoolOpt -> "false"
    FloatOpt(default) -> float.to_string(default)
    IntOpt(default) -> int.to_string(default)
    StringOpt(default) -> "\"" <> default <> "\""
  }
}
