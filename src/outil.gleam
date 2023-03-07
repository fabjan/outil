import gleam/io
import gleam/option.{Option}
import outil/error.{Reason}

/// Create a command with the given name and description, and pass it to the
/// given continuation function for further configuration.
///
/// The command gets a default implementation that returns an error.
pub fn command(
  name: String,
  description: String,
  argv: List(String),
  continue: fn(Command) -> a,
) -> a {
  continue(Command(name, description, [], [], argv))
}

/// Convenience function for handling the result of executing a command.
///
/// Print usage if there was a command line error or if the user asked for it.
///
/// Does nothing if the command returned an application error, assuming that
/// the application will handle it.
pub fn print_usage(return) {
  case return {
    CommandLineError(_, usage) -> io.println(usage)
    Help(usage) -> io.println(usage)
    _ -> Nil
  }
}

/// Convenience function for handling the result of executing a command.
///
/// Print usage if there was a command line error or if the user asked for it.
///
/// Exit with 2 if there was a command line error, 1 if there was a command
/// error, or 0 if the command was successful.
pub fn print_usage_and_exit(return) {
  print_usage(return)
  case return {
    CommandLineError(_, _) -> halt_program(2)
    CommandError(_) -> halt_program(1)
    Help(_) -> halt_program(0)
  }
}

/// A command line interface to a run function.
pub type Command {
  Command(
    name: String,
    description: String,
    arguments: List(Argument),
    options: List(Opt),
    argv: List(String),
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

/// Non-normal return values from executing a command.
pub type CommandReturn(a) {
  /// An error in parsing the command line.
  CommandLineError(reason: Reason, usage: String)
  /// An error in executing the command, `a` is your error value.
  CommandError(a)
  /// The user asked for help.
  Help(usage: String)
}

/// The result of executing a command.
pub type CommandResult(a, b) =
  Result(a, CommandReturn(b))

/// Parse a Bool from a string.
pub fn parse_bool(arg: String) -> Result(Bool, Nil) {
  case arg {
    "true" -> Ok(True)
    "false" -> Ok(False)
    _ -> Error(Nil)
  }
}

if erlang {
  external fn halt_program(Int) -> Nil =
    "erlang" "halt"
}

if javascript {
  external fn halt_program(Int) -> Nil =
    "./outil_ffi.mjs" "exit"
}
