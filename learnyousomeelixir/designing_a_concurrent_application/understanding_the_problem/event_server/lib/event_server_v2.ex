defmodule Reminder.EventServerV2 do
  require Logger

  defmodule State do
    defstruct server: "", name: "", to_go: [0]
  end

  @doc """
    To this reminder server we add:
      * a client api to spawn processes
      * a format to receive the timeout that is not limited by the VM limits

  iex(1)> NaiveDateTime.utc_now()
  ~N[2018-04-02 18:49:44.776000]
  iex(2)> Reminder.EventServerV2.start(self(), "Event", {{2018,04,02},{18,50,15}})
  #PID<0.106.0>
  iex(3)> flush()
  :ok
  iex(4)> NaiveDateTime.utc_now()
  ~N[2018-04-02 18:50:10.027000]
  iex(5)> NaiveDateTime.utc_now()
  ~N[2018-04-02 18:50:15.587000]
  iex(6)> flush()
  {:done, "Event"}
  :ok
  iex(7)> pid = Reminder.EventServerV2.start(self(), "Event", {{2200,01,01},{00,00,00}})
  #PID<0.112.0>
  iex(8)> Reminder.EventServerV2.cancel(pid)
  :ok
  iex(9)> flush()
  {:ok, #Reference<0.0.6.976>}
  :ok
  """
  def start(parent, event_name, date_time) do
    spawn(fn -> init(parent, event_name, date_time) end)
  end

  def start_link(parent, event_name, date_time) do
    spawn_link(fn -> init(parent, event_name, date_time) end)
  end

  def init(server, event_name, date_time) do
    loop(%State{server: server, name: event_name, to_go: time_to_go(date_time)})
  end

  def time_to_go(timeout = {{_, _, _}, {_, _, _}}) do
    {:ok, until_naive_datetime} = NaiveDateTime.from_erl(timeout)
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
      {:ok, ^ref} ->
        Process.demonitor(ref, [:flush])
        :ok

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
      {:cancel, client, ref} -> send(client, {:ok, ref})
    after
      t * 1000 ->
        case next do
          [] -> send(server, {:done, name})
          _ -> loop(%{state | to_go: [next]})
        end
    end
  end
end
