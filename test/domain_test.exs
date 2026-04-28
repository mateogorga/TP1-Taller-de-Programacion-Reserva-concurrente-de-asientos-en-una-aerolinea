defmodule DomainTest do
  use ExUnit.Case

  test "crear asiento disponible" do
    seat = %CondorDelSur.Seat{id: 1}
    assert seat.status == :available
  end
end
