defmodule CondorDelSur.FlightServer do
  def start do
    pid = spawn(fn -> loop(%{seats: %{}, reservations: %{}}) end)
    Process.register(pid, :flight_server)
    pid
  end

  defp loop(state) do
    receive do
      {:get_state, caller} ->
        send(caller, {:state, state})
        loop(state)

      {:create_seats, seat_ids} ->
        new_seats =
          seat_ids
          |> Enum.map(fn id -> {id, %CondorDelSur.Seat{id: id}} end)
          |> Enum.into(%{})

        new_state = %{state | seats: new_seats}
        loop(new_state)

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
