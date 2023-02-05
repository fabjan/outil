import gleam/option.{Option}

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

/// A function from the argument vector to a result.
pub type ArgvFunction(a) =
  fn(List(String)) -> Result(a, Error)

/// The type of continuation functions in building a command.
pub type WithArgument(a, b) =
  fn(ArgvFunction(a), Command(b)) -> Command(b)

/// Parse a Bool from a string.
pub fn parse_bool(arg: String) -> Result(Bool, Nil) {
  case arg {
    "true" -> Ok(True)
    "false" -> Ok(False)
    _ -> Error(Nil)
  }
}
