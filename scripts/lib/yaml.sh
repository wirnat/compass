# Shared YAML quoting for Compass scripts. Source this file; do not run it.

# awk function q(s): double-quotes s for YAML, escaping backslashes and quotes.
yaml_awk_lib='
function q(s,   out, i, c) {
  out = ""
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == "\\" || c == "\"") out = out "\\"
    out = out c
  }
  return "\"" out "\""
}
'

yaml_quote() {
  YAML_VALUE="$1" awk "$yaml_awk_lib"' BEGIN { print q(ENVIRON["YAML_VALUE"]) }'
}
