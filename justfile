alias t := test
alias cf := check-format
alias cd := check-dependencies
alias cc := check-compile
alias co := compile
alias c := check
alias f := format

# Run all tests or a specific test
test FILES='':
  mix test {{FILES}}

# Check the format of the code
check-format:
  mix format --check-formatted --dry-run

# Check the dependencies
check-dependencies:
  mix xref graph --label compile-connected --fail-above 63

# Check the code compiles without warnings
check-compile:
  mix compile --warnings-as-errors --force

# Run all the checks
check:
  just compile
  just check-format
  just check-dependencies
  just check-compile
  just test

# Compile the code
compile:
  mix compile

# Format the code
format:
  mix format
