
_default: 
  @just --list

_run-docker FLAGS='' *ARGS='':
  docker compose run --rm {{FLAGS}} event_relay {{ARGS}}

# Spin everything up
up: 
  docker compose up -d

# Spin everything down
down: 
  docker compose down 

# Did you try turning off and on again?
restart: 
  docker compose down && docker compose up -d

# Tail the docker compose logs
logs:
  docker compose logs -f

# Run any command in the container
run *ARGS='': (_run-docker '' ARGS)

# Run any command in the container with MIX_ENV=test
run-test *ARGS='': (_run-docker '-e MIX_ENV=test' ARGS)

# Run the tests
test: (_run-docker '-e MIX_ENV=test' 'mix test')

# Check the format of the code
check-format: (_run-docker '-e MIX_ENV=dev' 'mix format --check-formatted --dry-run') 

# Check the dependencies
check-dependencies: (_run-docker '-e MIX_ENV=dev' 'mix xref graph --label compile-connected --fail-above 63') 
  

# Check the code compiles without warnings
check-compile: (_run-docker '-e MIX_ENV=dev' 'mix compile --warnings-as-errors --force') 

# Compile the code
compile: (_run-docker '-e MIX_ENV=dev' 'mix compile') 
  
# Format the code
format: (_run-docker '-e MIX_ENV=dev' 'mix format') 

# Run all the checks
check:
  just compile
  just check-format
  just check-dependencies
  just check-compile
  just test

alias cf := check-format
alias cd := check-dependencies
alias cc := check-compile
alias co := compile
alias c := check
alias f := format
alias t := test
alias l := logs
