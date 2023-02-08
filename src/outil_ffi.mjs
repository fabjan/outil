export function exit(code) {
  if (globalThis.Deno) {
    return Deno.exit(code);
  } else {
    return process.exit(code);
  }
}
