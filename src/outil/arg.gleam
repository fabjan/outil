import gleam/float
import gleam/int
import gleam/list
import gleam/result
import outil.{
  Argument, BoolArgument, Command, FloatArgument, IntArgument, StringArgument,
  WithArgument, parse_bool,
}
import outil/error.{MalformedArgument,
  MissingArgument, OutOfPlaceOption, Reason}
import outil/help.{handle_error}

/// Add a positional bool argument to the command before continuing.
pub fn bool(cmd: Command, name: String, continue: WithArgument(Bool, a)) -> a {
  with_positional_argument(cmd, BoolArgument(name), parse_bool, continue)
}

/// Add a positional float argument to the command before continuing.
pub fn float(cmd: Command, name: String, continue: WithArgument(Float, a)) -> a {
  with_positional_argument(cmd, FloatArgument(name), float.parse, continue)
}

/// Add a positional int argument to the command before continuing.
pub fn int(cmd: Command, name: String, continue: WithArgument(Int, a)) -> a {
  with_positional_argument(cmd, IntArgument(name), int.parse, continue)
}

/// Add a positional string argument to the command before continuing.
pub fn string(cmd: Command, name: String, cont: WithArgument(String, a)) -> a {
  with_positional_argument(cmd, StringArgument(name), Ok, cont)
}

/// Add a positional argument to the command.
///
/// The continuation function gets a parser for the argument and the command
/// with the argument added, for further configuration.
fn with_positional_argument(
  cmd: Command,
  argument: Argument,
  parse: fn(String) -> Result(b, Nil),
  continue: WithArgument(b, a),
) -> a {
  let arg_pos = list.length(cmd.arguments)
  let arg_parser = positional_arg_parser(arg_pos, argument.name, parse)
  let arg_parser = fn(run_cmd: Command) {
    arg_parser(run_cmd.argv)
    |> result.map_error(fn(reason) { handle_error(reason, run_cmd) })
  }

  continue(arg_parser, append_argument(cmd, argument))
}

fn append_argument(cmd: Command, arg: Argument) -> Command {
  Command(
    cmd.name,
    cmd.description,
    list.append(cmd.arguments, [arg]),
    cmd.options,
    cmd.argv,
  )
}

fn positional_arg_parser(
  at: Int,
  name: String,
  parser: fn(String) -> Result(a, Nil),
) -> fn(List(String)) -> Result(a, Reason) {
  fn(args: List(String)) {
    case list.at(args, at) {
      Error(_) -> Error(MissingArgument(name))
      Ok(arg) ->
        case arg {
          "-" <> _ -> Error(OutOfPlaceOption(arg))
          _ ->
            parser(arg)
            |> result.map_error(fn(_) { MalformedArgument(name, arg) })
        }
    }
  }
}
