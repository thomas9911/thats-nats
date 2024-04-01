defmodule ThatsNats.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Gnat.ConnectionSupervisor,
       %{
         name: :gnat,
         connection_settings: [
           %{host: "127.0.0.1", port: 4222}
         ]
       }},
      ThatsNats.LoggerPullConsumer,
      service()
    ]

    opts = [strategy: :one_for_one, name: ThatsNats.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)

    bootstrap()

    {:ok, pid}
  end

  defp service do
    consumer_supervisor_settings = %{
      connection_name: :gnat,
      module: ThatsNats.Service,
      service_definition: %{
        name: "elixir_aas",
        description: "Runs elixir for you :ok",
        version: "0.1.0",
        endpoints: [
          %{
            name: "run",
            group_name: "elixir"
          }
        ]
      }
    }

    Supervisor.child_spec(
      {Gnat.ConsumerSupervisor, consumer_supervisor_settings},
      shutdown: 30_000
    )
  end

  def bootstrap do
    {:ok, %{created: _}} =
      Gnat.Jetstream.API.Stream.create(:gnat, %Gnat.Jetstream.API.Stream{
        name: "testing",
        subjects: []
      })

    {:ok, %{name: "elixir", stream_name: "testing"}} =
      Gnat.Jetstream.API.Consumer.create(:gnat, %Gnat.Jetstream.API.Consumer{
        durable_name: "elixir",
        stream_name: "testing"
      })

    :ok
  end
end
