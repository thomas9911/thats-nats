#!/bin/bash

# Start mix run in the background
mix run --no-halt &

# Get the PID of the mix process
mix_pid=$!

# Start cargo run in the background
cargo run &

# Get the PID of the cargo process
cargo_pid=$!

# Start go run in the background
go run ./services/thats-nats-go &

# Get the PID of the Go process
go_pid=$!

# Some other commands in the script

# Function to kill the background processes
cleanup() {
    echo "Cleaning up..."
    kill "$mix_pid" "$cargo_pid" "$go_pid"
}

echo "$mix_pid" "$cargo_pid" "$go_pid"
# Trap the EXIT signal to ensure cleanup is performed on script exit
trap cleanup EXIT SIGINT SIGTERM SIGQUIT

# Other commands in the script

read -rp "$(echo -e 'Press Control + C to exit\n\n\n\n\b')" _
