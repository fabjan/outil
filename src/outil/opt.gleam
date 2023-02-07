import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/result
import gleam/string
import outil.{
  BoolOpt, Command, Configure, FloatOpt, IntOpt, Opt, StringOpt, parse_bool,
}
import outil/error.{MalformedArgument, MissingArgument, Reason}
import outil/help.{handle_error}

/// Add a named bool option to the command before continuing.
pub fn bool(
  cmd: Command,
  long: String,
  description: String,
  continue: Configure(Bool, a, _),
) -> a {
  bool_(cmd, long, None, description, continue)
}

/// Add a bool option with a short name to the command before continuing.
pub fn bool_(
  cmd: Command,
  long: String,
  short: Option(String),
  description: String,
  continue: Configure(Bool, a, _),
) -> a {
  let opt = Opt(long, short, description, BoolOpt)
  let opt_parser = fn(run_cmd: Command) {
    bool_opt_parser(long, short)(run_cmd.argv)
    |> result.map_error(fn(reason) { handle_error(reason, run_cmd) })
  }

  continue(opt_parser, add_option(cmd, opt))
}

/// Add a named float option to the command before continuing.
pub fn float(
  cmd: Command,
  long: String,
  description: String,
  default: Float,
  continue: Configure(Float, a, _),
) -> a {
  float_(cmd, long, None, description, default, continue)
}

/// Add a float option with a short name to the command before continuing.
pub fn float_(
  cmd: Command,
  long: String,
  short: Option(String),
  description: String,
  default: Float,
  continue: Configure(Float, a, _),
) -> a {
  let opt = Opt(long, short, description, FloatOpt(default))

  with_named_option(cmd, opt, default, float.parse, continue)
}

/// Add a named int option to the command before continuing.
pub fn int(
  cmd: Command,
  long: String,
  description: String,
  default: Int,
  continue: Configure(Int, a, _),
) -> a {
  int_(cmd, long, None, description, default, continue)
}

/// Add an int option with a short name to the command before continuing.
pub fn int_(
  cmd: Command,
  long: String,
  short: Option(String),
  description: String,
  default: Int,
  continue: Configure(Int, a, _),
) -> a {
  let opt = Opt(long, short, description, IntOpt(default))

  with_named_option(cmd, opt, default, int.parse, continue)
}

/// Add a named string option to the command before continuing.
pub fn string(
  cmd: Command,
  long: String,
  description: String,
  default: String,
  continue: Configure(String, a, _),
) -> a {
  string_(cmd, long, None, description, default, continue)
}

/// Add a string option with a short name to the command before continuing.
pub fn string_(
  cmd: Command,
  long: String,
  short: Option(String),
  description: String,
  default: String,
  continue: Configure(String, a, _),
) -> a {
  let opt = Opt(long, short, description, StringOpt(default))

  with_named_option(cmd, opt, default, Ok, continue)
}

/// Add a named option to the command. Bring your own parser.
///
/// The continuation function gets a parser for the option and the command
/// with the option added, for further configuration.
pub fn with_named_option(
  cmd: Command,
  opt: Opt,
  default: b,
  parse: fn(String) -> Result(b, Nil),
  continue: Configure(b, a, _),
) -> a {
  let opt_parser = named_opt_parser(opt.long, opt.short, parse, default)
  let opt_parser = fn(run_cmd: Command) {
    opt_parser(run_cmd.argv)
    |> result.map_error(fn(reason) { handle_error(reason, run_cmd) })
  }

  continue(opt_parser, add_option(cmd, opt))
}

fn add_option(cmd: Command, opt: Opt) -> Command {
  Command(
    cmd.name,
    cmd.description,
    cmd.arguments,
    list.append(cmd.options, [opt]),
    cmd.argv,
  )
}

pub fn named_opt_parser(
  long: String,
  short: Option(String),
  parser: fn(String) -> Result(a, Nil),
  default: a,
) -> fn(List(String)) -> Result(a, Reason) {
  fn(args: List(String)) {
    case find(long, short, args) {
      #(None, _) -> Ok(default)
      #(Some(_), Some(arg)) ->
        parser(arg)
        |> result.map_error(fn(_) { MalformedArgument(long, arg) })
      #(Some(_), None) -> Error(MissingArgument(long))
    }
  }
}

// Bool opts are special because they can be specified without an argument.
fn bool_opt_parser(
  long: String,
  short: Option(String),
) -> fn(List(String)) -> Result(Bool, Reason) {
  fn(args: List(String)) {
    let #(opt, arg) = find(long, short, args)

    case opt {
      None -> Ok(False)
      Some(_) ->
        case arg {
          None -> Ok(True)
          Some(arg) ->
            parse_bool(arg)
            |> result.map_error(fn(_) { MalformedArgument(long, arg) })
        }
    }
  }
}

// Find an option named "--long" or "-short" in the list of arguments.
// If the string contains an equals sign, the option has an argument.
fn find(
  long: String,
  short: Option(String),
  args: List(String),
) -> #(Option(String), Option(String)) {
  let long_opt = "--" <> long
  let short_opt =
    short
    |> option.map(fn(s) { "-" <> s })

  let opt =
    list.find(
      args,
      fn(arg) {
        let is_long = string.starts_with(arg, long_opt)
        let is_short =
          short_opt
          |> option.map(fn(s) { string.starts_with(arg, s) })
          |> option.unwrap(False)
        is_long || is_short
      },
    )

  case opt {
    Error(_) -> #(None, None)
    Ok(opt) -> {
      let arg =
        string.split(opt, "=")
        |> list.at(1)

      #(Some(opt), option.from_result(arg))
    }
  }
}
