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
pub type Return {
  CommandLineError(reason: Reason, usage: String)
  Help(usage: String)
}

/// A function from the argument vector (in the given command) to a result.
pub type ArgvFunction(a) =
  fn(Command) -> Result(a, Return)

/// The type of continuation functions in building a command.
pub type WithArgument(a, b) =
  fn(ArgvFunction(a), Command) -> b

/// Parse a Bool from a string.
pub fn parse_bool(arg: String) -> Result(Bool, Nil) {
  case arg {
    "true" -> Ok(True)
    "false" -> Ok(False)
    _ -> Error(Nil)
  }
}
