# TP1 - Cóndor del Sur 

Sistema concurrente de reservas de asientos implementado en Elixir utilizando procesos manuales (sin OTP).

---

## Objetivo

Diseñar e implementar un sistema por CLI que simule la reserva de asientos para un vuelo y que permita mostrar concurrencia real sobre recursos limitados.

---

## Tecnologías

- Elixir
- Mix
- Procesos nativos (`spawn`, `send`, `receive`)

---

## Ejecución

### 1. Clonar el repositorio

```bash
git clone <URL_DEL_REPO>
cd condor_del_sur 
```

### 2. Instalar dependencias

```bash
mix deps.get
```

### 3. Ejecutar la demo

```bash
iex -S mix
c("demo.exs")
```

---


## Tests

```bash
mix test
```

---

## Modelado de dominio

Seat
 - id
 - status
    - :available
    - :reserved
    - :confirmed

Reservation
 - id
 - passenger
 - seat_id
 - status
    - :pending
    - :confirmed
    - :cancelled
    - :expired

---

## Procesos del sistema

### 1. FlightServer (proceso principal)

Responsable de:
 - mantener el estado
 - gestionar reservas
 - asegurar consistencia

### 2. Procesos cliente

Simulan usuarios concurrentes que:
 - intentan reservar asientos
 - reciben respuestas del servidor

### 3. Procesos auxiliares

Se crean con spawn para:
 - manejar expiración de reservas
 - evitar bloquear el sistema

---

## Uso de register

El proceso principal se registra para facilitar acceso global:

```bash
pid = FlightServer.start()
Process.register(pid, :flight_server)
```

Esto permite enviar mensajes sin necesidad de conocer el PID.

---

## Uso de monitor

Se utiliza Process.monitor/1 para observar procesos auxiliares:
 - detecta cuando terminan
 - recibe mensajes {:DOWN, ...}

```bash
Process.monitor(pid)
```

Esto permite registrar eventos sin bloquear el sistema.

---

## Demo 

La demo muestra:
 - creación de asientos
 - competencia concurrente por un asiento
 - confirmación de reserva
 - cancelación
 - expiración automática
 - estado final del sistema

Archivo: demo.exs

---

## Notas

 - No se utiliza OTP (GenServer, Supervisor, etc)
 - Implementación basada en procesos manuales

