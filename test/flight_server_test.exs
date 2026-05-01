defmodule FlightServerTest do
  use ExUnit.Case

  alias CondorDelSur.FlightServer

  test "crea asientos correctamente" do
    pid = FlightServer.start()

    send(pid, {:create_seats, [1, 2]})

    state = FlightServer.get_state(pid)

    assert map_size(state.seats) == 2
    assert state.seats[1].status == :available
    assert state.seats[2].status == :available
  end
end
