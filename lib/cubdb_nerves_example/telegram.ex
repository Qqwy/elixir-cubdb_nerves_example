defmodule CubdbNervesExample.Telegram do
  @moduledoc """
  A 'Telegram' is in this case a simple struct that is unique based on its timestamp value.

  In the actual application, this is a representation of a 'Dutch Smart Meter Requirements (DSMR) P1 Telegram', which contains measurement values of a smart electricity meter.
  """

  defstruct [:timestamp]

  def new() do
    timestamp = NaiveDateTime.utc_now |> NaiveDateTime.to_iso8601
    %__MODULE__{timestamp: timestamp}
  end
end
