import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import outil.{
  type Command, type CommandResult, type Opt, type OptValue, BoolOpt,
  CommandLineError, FloatOpt, Help, IntOpt, Opt, StringOpt,
}
import outil/error.{type Reason}

/// A function using the command line arguments which can return command error reasons.
pub type UseArgs(a) =
  fn(List(String)) -> Result(a, Reason)

/// Given a command, if the command line arguments contain `--help` or `-h`
/// then return a help "error" with the usage string.
/// Otherwise, pass the arguments to the given function and if it returns an
/// error, wrap it in a `CommandLineError` with the usage string.
pub fn wrap_usage(cmd: Command, continue: UseArgs(a)) -> CommandResult(a, _) {
  let argv_contains = fn(s) { list.contains(cmd.argv, s) }

  use args <- result.then(case argv_contains("--help") || argv_contains("-h") {
    True -> Error(Help(usage(cmd, None)))
    False -> Ok(cmd.argv)
  })

  continue(args)
  |> result.map_error(fn(reason) {
    let err_desc = case reason {
      error.MissingArgument(opt) -> "Missing argument for option: " <> opt
      error.MalformedArgument(opt, value) ->
        "Malformed argument for option: " <> opt <> " (" <> value <> ")"
      error.OutOfPlaceOption(opt) -> "Out of place option: " <> opt
    }
    CommandLineError(reason, usage(cmd, Some(err_desc)))
  })
}

fn usage(cmd: Command, err_desc: Option(String)) -> String {
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

  let opts =
    "\n\nOptions:\n" <> opts <> "\n" <> "  -h, --help  Show this help text and exit."

  let desc =
    err_desc
    |> option.map(fn(desc) { "ERROR! " <> desc })
    |> option.unwrap(cmd.description)

  cmd.name <> " -- " <> desc <> usage <> opts
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
