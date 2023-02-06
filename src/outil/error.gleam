/// Errors that can occur when parsing command line arguments.
pub type Reason {
  MalformedArgument(String, String)
  MissingArgument(String)
  OutOfPlaceOption(String)
}
