defmodule CondorDelSur.FlightServer do
  @reservation_timeout 5_000

  def start do
    spawn(fn -> loop(%{seats: %{}, reservations: %{}}) end)
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

        new_state = %{
          state
          | seats: Map.merge(state.seats, new_seats)
        }
        loop(new_state)

      {:reserve, passenger, seat_id, caller} ->
        case Map.get(state.seats, seat_id) do
          %CondorDelSur.Seat{status: :available} ->
            reservation_id = :erlang.unique_integer([:positive])

            reservation = %CondorDelSur.Reservation{
              id: reservation_id,
              passenger: passenger,
              seat_id: seat_id,
              status: :pending
            }

            updated_seat = %CondorDelSur.Seat{state.seats[seat_id] | status: :reserved}

            server = self()

            pid = spawn(fn ->
              :timer.sleep(@reservation_timeout)
              send(server, {:expire, reservation_id})
            end)

            Process.monitor(pid)

            new_state = %{
              state
              | seats: Map.put(state.seats, seat_id, updated_seat),
                reservations: Map.put(state.reservations, reservation_id, reservation)
            }

            send(caller, {:ok, reservation})
            loop(new_state)

          %CondorDelSur.Seat{} ->
            send(caller, {:error, :seat_not_available})
            loop(state)

          nil ->
            send(caller, {:error, :seat_not_found})
            loop(state)
        end

      {:confirm_reservation, reservation_id, caller} ->
        case Map.get(state.reservations, reservation_id) do
          %CondorDelSur.Reservation{status: :pending} = reservation ->

            updated_reservation =
              %CondorDelSur.Reservation{
                reservation | status: :confirmed
              }

            updated_seat =
              %CondorDelSur.Seat{
                state.seats[reservation.seat_id]
                | status: :confirmed
              }

            new_state = %{
              state
              | seats: Map.put(state.seats, reservation.seat_id, updated_seat),
                reservations: Map.put(state.reservations, reservation_id, updated_reservation)
            }

            send(caller, {:ok, updated_reservation})
            loop(new_state)

          %CondorDelSur.Reservation{} ->
            send(caller, {:error, :cannot_confirm})
            loop(state)

          nil ->
            send(caller, {:error, :reservation_not_found})
            loop(state)
        end

      {:cancel_reservation, reservation_id, caller} ->
        case Map.get(state.reservations, reservation_id) do
          %CondorDelSur.Reservation{status: :pending} = reservation ->
            updated_reservation = %CondorDelSur.Reservation{reservation | status: :cancelled}
            updated_seat = %CondorDelSur.Seat{state.seats[reservation.seat_id] | status: :available}

            new_state = %{
              state
              | seats: Map.put(state.seats, reservation.seat_id, updated_seat),
                reservations: Map.put(state.reservations, reservation_id, updated_reservation)
            }

            send(caller, {:ok, updated_reservation})
            loop(new_state)

          %CondorDelSur.Reservation{} ->
            send(caller, {:error, :cannot_cancel})
            loop(state)

          nil ->
            send(caller, {:error, :reservation_not_found})
            loop(state)
        end

      {:expire, reservation_id} ->
        case Map.get(state.reservations, reservation_id) do
          %CondorDelSur.Reservation{status: :pending} = reservation ->
            updated_reservation = %CondorDelSur.Reservation{reservation | status: :expired}
            updated_seat = %CondorDelSur.Seat{state.seats[reservation.seat_id] | status: :available}

            new_state = %{
              state
              | seats: Map.put(state.seats, reservation.seat_id, updated_seat),
                reservations: Map.put(state.reservations, reservation_id, updated_reservation)
            }

            loop(new_state)

          _ ->
            loop(state)
        end

      {:DOWN, _ref, :process, _pid, reason} ->
        IO.puts("Proceso monitoreado terminó: #{inspect(reason)}")
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

  def  available_seats(server) do
    state = get_state(server)
    state.seats |> Enum.filter(fn {_id, seat} -> seat.status == :available end) |> Enum.map(fn {id, _} -> id end)
  end
end
