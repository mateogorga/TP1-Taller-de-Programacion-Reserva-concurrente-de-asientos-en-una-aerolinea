defmodule CondorDelSur.FlightServer do
  def start do
    spawn(fn -> loop(%{seats: %{}, reservations: %{}}) end)
  end

  defp loop(state) do
    receive do
      {:get_state, caller} ->
        send(caller, {:state, state})
        loop(state)

      _ ->
        loop(state)
    end
  end

  def get_state(server) do
    send(server, {:get_state, self()})

    receive do
      {:state, state} -> state
    end
  end
end
