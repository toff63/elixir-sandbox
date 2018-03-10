defmodule Event.ServerV2 do
  defmodule State do
    defstruct server: "", name: "", to_go: [0]
  end

  @doc """
  iex(1)> Event.ServerV2.start(self(), "Event", NaiveDateTime.utc_now())
  #PID<0.105.0>
  iex(2)> flush()
  {:done, "Event"}
  :ok
  iex(3)> pid = Event.ServerV2.start(self(), "Event", ~N[2200-01-01 00:00:00])
  #PID<0.108.0>
  iex(4)> Event.ServerV2.cancel(pid)
  :ok
  iex(5)> flush()
  {:ok, #Reference<0.0.3.506>}
  :ok
  """
  def start(parent, event_name, until_naive_datetime) do
    spawn(fn -> init(parent, event_name, until_naive_datetime) end)
  end

  def start_link(parent, event_name, until_naive_datetime) do
    spawn_link(fn -> init(parent, event_name, until_naive_datetime) end)
  end

  def init(server, event_name, until_naive_datetime) do
    loop(%State{server: server, name: event_name, to_go: time_to_go(until_naive_datetime)})
  end

  def time_to_go(until_naive_datetime) do
    to_go = NaiveDateTime.diff(until_naive_datetime, NaiveDateTime.utc_now())
    normalize(to_go)
  end

  @doc """
   Monitor in case the process is already dead
  """
  def cancel(pid) do
    ref = Process.monitor(pid)
    send(pid, {:cancel, self(), ref})

    receive do
      {^ref, ok} ->
        Process.demonitor(ref, [:flush])
        ok

      {:DOWN, ^ref, :process, _pid, _reason} ->
        :ok
    end
  end

  @doc """
  Because Erlang is limited to about 49 days (49*24*60*60*1000) in
  milliseconds, the following function is used
  """
  def normalize(n) do
    limit = 49 * 24 * 60 * 60
    [rem(n, limit) | List.duplicate(limit, div(n, limit))]
  end

  def loop(state = %State{server: server, name: name, to_go: [t | next]}) do
    receive do
      {:cancel, server, ref} -> send(server, {:ok, ref})
    after
      t * 1000 ->
        case next do
          [] -> send(server, {:done, name})
          _ -> loop(%{state | to_go: [next]})
        end
    end
  end
end
