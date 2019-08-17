defmodule CubdbNervesExample.FakeTelegramGenerator do
  require Solution
  import Solution

  require Logger

  use ExActor.GenServer, export: __MODULE__

  defstart start_link(_) do
    Process.send_after(self(), :send_fake_telegram, 0)
    initial_state(:ok)
  end

  defhandleinfo :send_fake_telegram do
    swith  ok(telegram) <- generate_fake_telegram(),
           ok() <- CubdbNervesExample.DB.put_telegram(telegram) do
      :ok
    else
      error(error) ->
        Logger.error("Error encountred during telegram generation/insertion #{inspect error}")

    end
    Process.send_after(self(), :send_fake_telegram, 0)

    noreply
  end

  def generate_fake_telegram() do
    CubdbNervesExample.Telegram.new()
  end
end
