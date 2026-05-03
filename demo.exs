alias CondorDelSur.FlightServer

IO.puts("=== INICIO DEMO TP1 CONDOR DEL SUR ===")

# 1. Start + register
pid = FlightServer.start()
Process.register(pid, :flight_server)

IO.puts("\n== Creando asientos ==")
send(:flight_server, {:create_seats, [1, 2, 3]})

:timer.sleep(500)

IO.puts("Asientos disponibles:")
IO.inspect(FlightServer.available_seats(:flight_server))

# 2. Competencia concurrente por un asiento
IO.puts("\n== Concurrencia: múltiples pasajeros por asiento 1 ==")

for name <- ["Juan", "Ana", "Pedro", "Luis"] do
  spawn(fn ->
    send(:flight_server, {:reserve, name, 1, self()})

    receive do
      msg ->
        IO.puts("#{name} -> #{inspect(msg)}")
    end
  end)
end

:timer.sleep(1000)

IO.puts("\nEstado después de concurrencia:")
IO.inspect(FlightServer.get_state(:flight_server))

# 3. Confirmación por pago
IO.puts("\n== Confirmando reserva ==")

send(:flight_server, {:reserve, "Carlos", 2, self()})

reservation =
  receive do
    {:ok, r} -> r
  end

send(:flight_server, {:confirm_reservation, reservation.id, self()})

receive do
  msg -> IO.puts("Confirmación: #{inspect(msg)}")
end

# 4. Cancelación
IO.puts("\n== Cancelando reserva ==")

send(:flight_server, {:reserve, "Maria", 3, self()})

reservation2 =
  receive do
    {:ok, r} -> r
  end

send(:flight_server, {:cancel_reservation, reservation2.id, self()})

receive do
  msg -> IO.puts("Cancelación: #{inspect(msg)}")
end

# 5. Expiración automática
IO.puts("\n== Probando expiración automática ==")

send(:flight_server, {:reserve, "Pedro", 3, self()})

receive do
  {:ok, r} -> IO.puts("Reserva creada (esperando expiración): #{r.id}")
end

IO.puts("Esperando 5 segundos...")

:timer.sleep(6000)

IO.puts("\nEstado después de expiración:")
IO.inspect(FlightServer.get_state(:flight_server))

# 6. Estado final
IO.puts("\n=== ESTADO FINAL ===")
IO.inspect(FlightServer.get_state(:flight_server))
