defmodule CubdbNervesExample.DB do

  require Logger

  @moduledoc """
  A wrapper of CubDB, as used to store telegrams,
  in combination with the 'State' that keeps track (in the real application) how many
  of these telegrams have been synchronized with the remote server already.

  When started in a supervision tree, starts a CubDB GenServer instance with the appropriate settings:
  - use auto file synching
  - use auto compaction
  - Allow the GenServer to be registered un ther the name #{__MODULE__}.

  Instead of using the CubDB's functions directly,
  other parts of the application ought to use the functions this module exports.
  """

  defmodule State do
    defstruct [last_processed_timestamp: nil]

    def new do
      %__MODULE__{}
    end
  end

  def child_spec(_) do
    %{id: __MODULE__, start: {CubDB, :start_link, [Application.get_env(:cubdb_nerves_example, :dsmr_db_location, "data/dsmr"), [auto_file_sync: true, auto_compact: true], [name: __MODULE__]]}}
  end

  def get_state do
    CubDB.get(__MODULE__, :state, State.new)
  end

  def put_state(new_state) do
    CubDB.put(__MODULE__, :state, new_state)
  end

  def fetch_telegram(timestamp) do
    CubDB.fetch(__MODULE__, {:telegram, timestamp})
  end

  def put_telegram(telegram = %{}) do
    Logger.debug("Putting Telegram `#{inspect(telegram)}`.")
    CubDB.put(__MODULE__, {:telegram, telegram.timestamp}, telegram)
  end

  @doc """
  Calls the `fun` function on each telegrams that is new since
  the last saved state's timestamp.

  `reducer` receives as input a `%Telegram{}` and `%State{}` and should return a new `%State{}`.
  """
  def select_unprocessed_telegrams(reducer) do
    state = get_state()
    monoidal_reducer = {state, fn {_, v}, acc -> reducer.(v, acc) end}
  {:ok, new_state} = select_telegrams_newer_than(state.last_processed_timestamp, monoidal_reducer)
    put_state(new_state)
  end

  defp select_telegrams_newer_than(timestamp, reducer) do
    CubDB.select(__MODULE__,
      min_key: {{:telegram, timestamp}, :excluded},
      max_key: {:telegram, timestamp, nil},
      reduce: reducer
    )
  end

  @doc """
  Use this function to check how many rows the database currently contains.
  """
  def count_db_rows do
    CubDB.select(__MODULE__, reduce: {0, fn _, acc -> acc + 1 end})
  end


  @doc """
  Use this function to check how many Telegram-rows the database currently contains.
  """
  def count_telegrams do
    CubDB.select(__MODULE__,
      min_key: {{:telegram, nil}, :excluded},
      max_key: {:telegram, nil, nil},
      reduce: {0, fn _, acc -> acc + 1 end})
  end
end
