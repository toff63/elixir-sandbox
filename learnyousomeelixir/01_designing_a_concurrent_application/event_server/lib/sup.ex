defmodule Sup do
  require Logger

  defmodule State do
    defstruct module: Reminder, func: :start_link, args: []
  end

  @doc """
  Create a supervisor for the latest version of the Reminder server

      iex(1)> sup_pid = Sup.start(Reminder.ServerV2, [])
      #PID<0.128.0>
      iex(2)> Process.whereis(:'Reminder.Server')
      #PID<0.129.0>
      iex(3)> Process.exit(Process.whereis(:'Reminder.Server'), :die)

      23:48:27.903 [info]  Process #PID<0.129.0> exited for reason :die
      true
      iex(4)> Process.whereis(:'Reminder.Server')
      #PID<0.132.0>
      iex(5)> Process.exit(sup_pid, :shutdown)
      true
      iex(6)> Process.whereis(:'Reminder.Server')
      nil
  """

  def start(mod, args) do
    spawn(fn -> init(mod, args) end)
  end

  def start_link(mod, args) do
    spawn_link(fn -> init(mod, args) end)
  end

  def init(mod, args) do
    Process.flag(:trap_exit, true)
    loop(%State{module: mod, func: :start_link, args: args})
  end

  def loop(state = %State{module: module, func: func, args: args}) do
    pid = apply(module, func, args)

    receive do
      {:EXIT, _from, :shutdown} ->
        exit(:shutdown)

      {:EXIT, ^pid, reason} ->
        Logger.info("Process #{inspect(pid)} exited for reason #{inspect(reason)}")
        loop(state)
    end
  end
end
