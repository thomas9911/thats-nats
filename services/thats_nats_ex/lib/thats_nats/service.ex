defmodule ThatsNats.Service do
  use Gnat.Services.Server

  # Can also match on endpoint or group
  def request(%{body: body}, "run", "elixir") do
    {result, _} = Code.eval_string(body)

    {:reply, Jason.encode!(%{result: result})}

  rescue
    e in CompileError -> {:reply, Jason.encode!(%{error: e})}
  end

  # defining an error handler is optional, the default one will just call Logger.error for you
  def error(%{gnat: gnat, reply_to: reply_to}, _error) do
    Gnat.pub(gnat, reply_to, "Something went wrong and I can't handle your request")
  end
end
