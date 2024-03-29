defmodule ThatsNats.LoggerPullConsumer do
  use Jetstream.PullConsumer

  def start_link([]) do
    Jetstream.PullConsumer.start_link(__MODULE__, [])
  end

  @impl true
  def init([]) do
    {:ok, nil, connection_name: :gnat, stream_name: "testing", consumer_name: "elixir"}
  end

  @impl true
  def handle_message(message, state) do
    IO.inspect(message)
    {:ack, state}
  end
end
