defmodule CondorDelSur.Seat do
  defstruct id: nil, status: :available
end

defmodule CondorDelSur.Reservation do
  defstruct id: nil,
            passenger: nil,
            seat_id: nil,
            status: :pending
end
