import gleam/float
import gleam/int
import gleam/list
import gleam/result
import outil/core.{
  Argument, BoolArgument, Command, Error, FloatArgument, IntArgument,
  MalformedArgument, MissingArgument, OutOfPlaceOption, StringArgument,
  WithArgument, parse_bool,
}

/// Add a positional bool argument to the command before continuing.
pub fn bool(
  cmd: Command(a),
  name: String,
  continue: WithArgument(Bool, a),
) -> Command(a) {
  with_positional_argument(cmd, BoolArgument(name), parse_bool, continue)
}

/// Add a positional float argument to the command before continuing.
pub fn float(
  cmd: Command(a),
  name: String,
  continue: WithArgument(Float, a),
) -> Command(a) {
  with_positional_argument(cmd, FloatArgument(name), float.parse, continue)
}

/// Add a positional int argument to the command before continuing.
pub fn int(
  cmd: Command(a),
  name: String,
  continue: WithArgument(Int, a),
) -> Command(a) {
  with_positional_argument(cmd, IntArgument(name), int.parse, continue)
}

/// Add a positional string argument to the command before continuing.
pub fn string(
  cmd: Command(a),
  name: String,
  continue: WithArgument(String, a),
) -> Command(a) {
  with_positional_argument(cmd, StringArgument(name), Ok, continue)
}

/// Add a positional argument to the command.
///
/// The continuation function gets a parser for the argument and the command
/// with the argument added, for further configuration.
fn with_positional_argument(
  cmd: Command(a),
  argument: Argument,
  parse: fn(String) -> Result(b, Nil),
  continue: WithArgument(b, a),
) -> Command(a) {
  let arg_pos = list.length(cmd.arguments)
  let arg_parser = positional_arg_parser(arg_pos, argument.name, parse)

  continue(arg_parser, append_argument(cmd, argument))
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
