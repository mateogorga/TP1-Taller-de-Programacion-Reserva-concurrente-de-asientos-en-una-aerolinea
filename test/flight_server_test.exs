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

  test "reserva un asiento disponible" do
    pid = FlightServer.start()

    send(pid, {:create_seats, [1]})

    send(pid, {:reserve, "Mateo Gorga", 1, self()})

    assert_receive {:ok, reservation}
    assert reservation.passenger == "Mateo Gorga"
    assert reservation.seat_id == 1
    assert reservation.status == :pending
  end

  test "no puede reservar un asiento ocupado" do
    pid = FlightServer.start()

    send(pid, {:create_seats, [1]})

    send(pid, {:reserve, "Mateo Gorga", 1, self()})
    assert_receive {:ok, _}

    send(pid, {:reserve, "Mateo Gorga", 1, self()})
    assert_receive {:error, :seat_not_available}
  end

  test "confirma una reserva pendiente" do
    pid = FlightServer.start()

    send(pid, {:create_seats, [1]})
    send(pid, {:reserve, "Juan", 1, self()})
    assert_receive {:ok, reservation}

    send(pid, {:confirm_reservation, reservation.id, self()})
    assert_receive {:ok, updated}

    assert updated.status == :confirmed

    state = FlightServer.get_state(pid)
    assert state.seats[1].status == :confirmed
  end

  test "cancela una reserva pendiente" do
    pid = FlightServer.start()

    send(pid, {:create_seats, [1]})

    send(pid, {:reserve, "Mateo Gorga", 1, self()})
    assert_receive {:ok, reservation}

    send(pid, {:cancel_reservation, reservation.id, self()})
    assert_receive {:ok, cancelled_reservation}
    assert cancelled_reservation.status == :cancelled
  end

  test "no cancela una reserva confirmada" do
    pid = FlightServer.start()

    send(pid, {:create_seats, [1]})

    send(pid, {:reserve, "Mateo Gorga", 1, self()})
    assert_receive {:ok, reservation}

    send(pid, {:confirm_reservation, reservation.id, self()})
    assert_receive {:ok, _}

    send(pid, {:cancel_reservation, reservation.id, self()})
    assert_receive {:error, :cannot_cancel}
  end

  test "expira una reserva pendiente" do
    pid = FlightServer.start()

    send(pid, {:create_seats, [1]})

    send(pid, {:reserve, "Mateo Gorga", 1, self()})
    assert_receive {:ok, reservation}

    :timer.sleep(6_000)

    state = FlightServer.get_state(pid)
    expired_reservation = state.reservations[reservation.id]

    assert expired_reservation.status == :expired
    assert state.seats[1].status == :available
  end

end
