import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/result
import gleam/string

/// A command line interface to a run function.
pub type Command(a) {
  Command(
    name: String,
    description: String,
    arguments: List(Argument),
    options: List(Opt),
    run: fn(List(String)) -> Result(a, Error),
  )
}

/// A positional command line argument.
pub type Argument {
  BoolArgument(name: String)
  FloatArgument(name: String)
  IntArgument(name: String)
  StringArgument(name: String)
}

/// A command line option/flag.
pub type Opt {
  Opt(long: String, short: Option(String), description: String, value: OptValue)
}

/// The type and default value of an option.
pub type OptValue {
  BoolOpt
  FloatOpt(default: Float)
  IntOpt(default: Int)
  StringOpt(default: String)
}

/// Errors that can occur when parsing command line arguments.
pub type Error {
  MalformedArgument(String, String)
  MissingArgument(String)
  NotImplemented(String)
  OutOfPlaceOption(String)
}

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

/// A function from the argument vector to a result.
type ArgvFunction(a) =
  fn(List(String)) -> Result(a, Error)

/// The type of continuation functions in building a command.
type WithArgument(a, b) =
  fn(ArgvFunction(a), Command(b)) -> Command(b)

/// Add the code to evaluate when the command is executed.
pub fn implement(cmd: Command(a), run: ArgvFunction(a)) -> Command(a) {
  Command(cmd.name, cmd.description, cmd.arguments, cmd.options, run)
}

/// Execute the command with the given argument vector.
pub fn execute(cmd: Command(a), args: List(String)) -> Result(a, Error) {
  cmd.run(args)
}

/// Add a positional bool argument to the command before continuing.
pub fn bool_arg(
  cmd: Command(a),
  name: String,
  continue: WithArgument(Bool, a),
) -> Command(a) {
  positional_arg(cmd, BoolArgument(name), parse_bool, continue)
}

/// Add a positional float argument to the command before continuing.
pub fn float_arg(
  cmd: Command(a),
  name: String,
  continue: WithArgument(Float, a),
) -> Command(a) {
  positional_arg(cmd, FloatArgument(name), float.parse, continue)
}

/// Add a positional int argument to the command before continuing.
pub fn int_arg(
  cmd: Command(a),
  name: String,
  continue: WithArgument(Int, a),
) -> Command(a) {
  positional_arg(cmd, IntArgument(name), int.parse, continue)
}

/// Add a positional string argument to the command before continuing.
pub fn string_arg(
  cmd: Command(a),
  name: String,
  continue: WithArgument(String, a),
) -> Command(a) {
  positional_arg(cmd, StringArgument(name), Ok, continue)
}

/// Add a named bool option to the command before continuing.
pub fn bool_opt(
  cmd: Command(a),
  long: String,
  description: String,
  continue: WithArgument(Bool, a),
) -> Command(a) {
  bool_opt_(cmd, long, None, description, continue)
}

/// Add a bool option with a short name to the command before continuing.
pub fn bool_opt_(
  cmd: Command(a),
  long: String,
  short: Option(String),
  description: String,
  continue: WithArgument(Bool, a),
) -> Command(a) {
  let opt = Opt(long, short, description, BoolOpt)

  continue(bool_opt_parser(long, short), add_option(cmd, opt))
}

/// Add a named float option to the command before continuing.
pub fn float_opt(
  cmd: Command(a),
  long: String,
  description: String,
  default: Float,
  continue: WithArgument(Float, a),
) -> Command(a) {
  float_opt_(cmd, long, None, description, default, continue)
}

/// Add a float option with a short name to the command before continuing.
pub fn float_opt_(
  cmd: Command(a),
  long: String,
  short: Option(String),
  description: String,
  default: Float,
  continue: WithArgument(Float, a),
) -> Command(a) {
  let opt = Opt(long, short, description, FloatOpt(default))

  named_opt(cmd, opt, default, float.parse, continue)
}

/// Add a named int option to the command before continuing.
pub fn int_opt(
  cmd: Command(a),
  long: String,
  description: String,
  default: Int,
  continue: WithArgument(Int, a),
) -> Command(a) {
  int_opt_(cmd, long, None, description, default, continue)
}

/// Add an int option with a short name to the command before continuing.
pub fn int_opt_(
  cmd: Command(a),
  long: String,
  short: Option(String),
  description: String,
  default: Int,
  continue: WithArgument(Int, a),
) -> Command(a) {
  let opt = Opt(long, short, description, IntOpt(default))

  named_opt(cmd, opt, default, int.parse, continue)
}

/// Add a named string option to the command before continuing.
pub fn string_opt(
  cmd: Command(a),
  long: String,
  description: String,
  default: String,
  continue: WithArgument(String, a),
) -> Command(a) {
  string_opt_(cmd, long, None, description, default, continue)
}

/// Add a string option with a short name to the command before continuing.
pub fn string_opt_(
  cmd: Command(a),
  long: String,
  short: Option(String),
  description: String,
  default: String,
  continue: WithArgument(String, a),
) -> Command(a) {
  let opt = Opt(long, short, description, StringOpt(default))

  named_opt(cmd, opt, default, Ok, continue)
}

/// Return a string describing the usage of the given command.
pub fn usage(cmd: Command(a)) -> String {
  let args =
    cmd.arguments
    |> list.map(fn(arg) {
      case arg {
        BoolArgument(name) -> name
        FloatArgument(name) -> name
        IntArgument(name) -> name
        StringArgument(name) -> name
      }
    })
    |> list.map(fn(arg) { "<" <> arg <> ">" })
    |> string.join(" ")

  let opts =
    cmd.options
    |> list.map(fn(opt) {
      let Opt(long, short, desc, value) = opt
      let short = option.map(short, fn(s) { "-" <> s <> ", " })
      let short = option.unwrap(short, "")
      let long = "--" <> long
      let typ = case value {
        BoolOpt -> "bool"
        FloatOpt(_) -> "float"
        IntOpt(_) -> "int"
        StringOpt(_) -> "string"
      }
      let default = case value {
        BoolOpt -> "false"
        FloatOpt(default) -> float.to_string(default)
        IntOpt(default) -> int.to_string(default)
        StringOpt(default) -> "\"" <> default <> "\""
      }
      let meta = "(" <> typ <> ", default: " <> default <> ")"

      short <> long <> "  " <> desc <> " " <> meta
    })
    |> list.map(fn(opt) { "  " <> opt })
    |> string.join("\n")

  let opts = "Options:\n" <> opts <> "\n"

  cmd.description <> "\n\n" <> "Usage: " <> cmd.name <> " " <> args <> "\n\n" <> opts
}

/// Add a positional argument to the command.
///
/// The continuation function gets a parser for the argument and the command
/// with the argument added, for further configuration.
fn positional_arg(
  cmd: Command(a),
  argument: Argument,
  parse: fn(String) -> Result(b, Nil),
  continue: WithArgument(b, a),
) -> Command(a) {
  let arg_pos = list.length(cmd.arguments)
  let arg_parser = positional_arg_parser(arg_pos, argument.name, parse)

  continue(arg_parser, append_argument(cmd, argument))
}

/// Add a named option to the command. Bring your own parser.
///
/// The continuation function gets a parser for the option and the command
/// with the option added, for further configuration.
pub fn named_opt(
  cmd: Command(a),
  opt: Opt,
  default: b,
  parse: fn(String) -> Result(b, Nil),
  continue: WithArgument(b, a),
) -> Command(a) {
  continue(
    named_opt_parser(opt.long, opt.short, parse, default),
    add_option(cmd, opt),
  )
}

fn append_argument(cmd: Command(a), arg: Argument) -> Command(a) {
  Command(
    cmd.name,
    cmd.description,
    list.append(cmd.arguments, [arg]),
    cmd.options,
    cmd.run,
  )
}

fn add_option(cmd: Command(a), opt: Opt) -> Command(a) {
  Command(
    cmd.name,
    cmd.description,
    cmd.arguments,
    list.append(cmd.options, [opt]),
    cmd.run,
  )
}

fn positional_arg_parser(
  at: Int,
  name: String,
  parser: fn(String) -> Result(a, Nil),
) -> fn(List(String)) -> Result(a, Error) {
  fn(args: List(String)) {
    case list.at(args, at) {
      Error(_) -> Error(MissingArgument(name))
      Ok(arg) ->
        case arg {
          "-" -> Error(OutOfPlaceOption(arg))
          _ ->
            parser(arg)
            |> result.map_error(fn(_) { MalformedArgument(name, arg) })
        }
    }
  }
}

fn named_opt_parser(
  long: String,
  short: Option(String),
  parser: fn(String) -> Result(a, Nil),
  default: a,
) -> fn(List(String)) -> Result(a, Error) {
  fn(args: List(String)) {
    case find_opt(long, short, args) {
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
) -> fn(List(String)) -> Result(Bool, Error) {
  fn(args: List(String)) {
    let #(opt, arg) = find_opt(long, short, args)

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
fn find_opt(
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

fn parse_bool(arg: String) -> Result(Bool, Nil) {
  case arg {
    "true" -> Ok(True)
    "false" -> Ok(False)
    _ -> Error(Nil)
  }
}
