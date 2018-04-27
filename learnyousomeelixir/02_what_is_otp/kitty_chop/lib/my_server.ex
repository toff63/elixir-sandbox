defmodule MyServer do
  def start(module, initial_state) do
    spawn(fn -> init(module, initial_state) end)
  end

  def start_link(module, initial_state) do
    spawn_link(fn -> init(module, initial_state) end)
  end

  @spec call(pid, any()) :: any()
  def call(pid, msg) do
    ref = Process.monitor(pid)
    send(pid, {:sync, msg, self(), ref})

    receive do
      {reply, ^ref} ->
        Process.demonitor(ref, [:flush])
        reply

      {:DOWN, ^ref, :process, _pid, reason} ->
        Process.exit(self(), reason)
    after
      5000 ->
        Process.exit(self(), :timeout)
    end
  end

  @spec cast(pid, any()) :: any()
  def cast(pid, msg) do
    send(pid, {:async, msg})
    :ok
  end

  def reply(reply, {pid, ref}) do
    send(pid, {reply, ref})
  end

  defp init(module, initial_state) do
    loop(module, initial_state)
  end

  
  @spec loop(module(), any()) :: any()
  defp loop(module, state) do
    receive do
      {:async, msg} ->
        loop(module, apply(module, :handle_cast, [msg, state]))

      {:sync, msg, pid, ref} ->
        loop(module, apply(module, :handle_call, [msg, {pid, ref}, state]))
    end
  end
end
