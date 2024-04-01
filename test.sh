#! /bin/bash

inner_nats() {
    ./nats "$@"
}

# list found microservices
inner_nats micro list

# test against elixir service
inner_nats request 'elixir.run' ':rand.bytes(32) |> Base.encode32(padding: false)'

# test against rust service that runs rhai script
inner_nats request 'rhai.run' 'rand_float(0.0, 12345.0)'
