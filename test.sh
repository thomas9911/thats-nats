#! /bin/bash

inner_nats() {
    ./nats "$@"
}

# test against elixir service
inner_nats request 'elixir.run' ':rand.bytes(32) |> Base.encode32(padding: false)'

inner_nats request 'rust' 'rand_float(0.0, 12345.0)'
