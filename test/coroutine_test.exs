defmodule CoroutineTest do
  use ExUnit.Case
  doctest Coroutine
  use Coroutine

  def iterate(over, max) when over > max,
    do: :ok

  def iterate(n, max) do
    yield n
    iterate(n + 1, max)
  end

  test "simple iterator" do
    cr = Coroutine.spawn(fn -> iterate(0, 2) end)
    assert Process.alive?(Coroutine.pid(cr))
    assert {:next, 0} = Coroutine.next(cr)
    assert {:next, 1} = Coroutine.next(cr)
    assert {:next, 2} = Coroutine.next(cr)
    assert {:done, nil} = Coroutine.next(cr)
    assert false === Process.alive?(Coroutine.pid(cr))

    assert catch_exit(Coroutine.next(cr, nil, 100)) === :timeout
  end
end
