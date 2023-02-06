import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import outil.{
  BoolOpt, Command, CommandLineError, FloatOpt, Help, IntOpt, Opt, OptValue,
  Return, StringOpt,
}
import outil/error.{Reason}

/// Transform parse errors into a return value, this is where we
/// check for the help flag.
pub fn handle_error(reason: Reason, cmd: Command) -> Return {
  // This solution (piggybacking on the error handling) is not ideal since it
  // means we can only show help for commands that try to parse any arguments
  // or options. But if your command doesn't take any arguments or options
  // then you probably don't need this library at all.
  case list.contains(cmd.argv, "--help") || list.contains(cmd.argv, "-h") {
    True -> Help(usage(cmd))
    False -> CommandLineError(reason, usage(cmd))
  }
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
