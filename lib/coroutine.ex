defmodule Coroutine do
  defstruct pid: nil, parent: nil, mref: nil

  defmacro __using__(_) do
    quote do
      import Coroutine, only: [yield: 1]
    end
  end

  def spawn(fun) when is_function(fun, 0) do
    parent = self()
    {pid, mref} = Kernel.spawn_monitor(fn -> init_call(fun, parent) end)
    %__MODULE__{pid: pid, parent: parent, mref: mref}
  end

  def pid(%__MODULE__{pid: pid}), do: pid

  def next(coroutine, message \\ nil, timeout \\ 5000)

  def next(%__MODULE__{parent: parent} = cr, msg, timeout)
      when parent == self() do
    %__MODULE__{pid: pid, mref: mref} = cr
    ref = make_ref()
    send(pid, {__MODULE__, :next, parent, ref, msg})

    receive do
      {^ref, value} ->
        {:next, value}

      {:DOWN, ^mref, _, ^pid, :normal} ->
        {:done, nil}

      {:DOWN, ^mref, _, ^pid, reason} ->
        {:error, reason}
    after
      timeout -> exit(:timeout)
    end
  end

  def yield(value) do
    parent = get_parent()

    receive do
      {__MODULE__, :next, ^parent, ref, msg} ->
        send(parent, {ref, value})
        msg
    end
  end

  @parent_key {__MODULE__, :parent_pid}

  def put_parent(parent) when is_pid(parent),
    do: Process.put(@parent_key, parent)

  def get_parent(),
    do: Process.get(@parent_key)

  defp init_call(fun, parent) do
    put_parent(parent)
    fun.()
  end
end
