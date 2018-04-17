defmodule Reminder.Server do
    require Logger

    defmodule State do
        defstruct events: [], clients: []
    end
    defmodule Event do
        defstruct name: "", description: "", pid: "", timeout: {{1970,01,01}, {00,00,00}}
    end

    @doc """
    This version adds the Reminder server which interacts with event processes. It handles 
        * client registration
        * add of reminder
        * cancel of reminers
        * inform client when a reminder is done
        * hot swap code
        * shutdown
    """
    def start() do
        spawn(fn -> init() end)
    end

    def start_link() do
        spawn_link(fn -> init() end)
    end
    
    def init() do
        loop(%State{events: Map.new(), clients: Map.new()})
    end

    def time_to_go(timeout = {{_, _, _}, {_, _, _}}) do
        {:ok, until_naive_datetime} = NaiveDateTime.from_erl(timeout)
        to_go = NaiveDateTime.diff(until_naive_datetime, NaiveDateTime.utc_now())
        normalize(to_go)
    end

  @doc """
  Because Erlang is limited to about 49 days (49*24*60*60*1000) in
  milliseconds, the following function is used
  """
  def normalize(n) do
    limit = 49 * 24 * 60 * 60
    [rem(n, limit) | List.duplicate(limit, div(n, limit))]
  end


    def valid_datetime(timeout = {{_, _, _}, {_, _, _}}) do
        case NaiveDateTime.from_erl(timeout) do
            {:ok, date} -> 
                case NaiveDateTime.compare(date, NaiveDateTime.utc_now) do
                    :gt -> true
                    _ -> false
                end
            {:error, _} -> false
        end
    end
    
    @doc """
        iex(1)> pid = Reminder.Server.start()
        #PID<0.120.0>
        iex(2)> repl_pid = self()
        #PID<0.118.0>
        iex(3)> msg_ref = make_ref()
        #Reference<0.0.7.488>
        iex(4)> send(pid, {{:subscribe, repl_pid}, repl_pid, msg_ref})
        {{:subscribe, #PID<0.118.0>}, #PID<0.118.0>, #Reference<0.0.7.488>}
        iex(5)> flush()
        {:ok, #Reference<0.0.7.488>}
        :ok
        iex(6)> msg_ref = make_ref()
        #Reference<0.0.7.505>
        iex(7)> send(pid, {{:add, "event", "this is an event", {{2018,04,02},{20,54,15}}}, repl_pid, msg_ref})
        {{:add, "event", "this is an event", {{2018, 4, 2}, {20, 54, 15}}},
        #PID<0.118.0>, #Reference<0.0.7.505>}
        iex(8)> flush()
        {:ok, #Reference<0.0.7.505>}
        :ok
        iex(9)> flush()
        {:done, "event", "this is an event"}
        :ok
        iex(10)> msg_ref = make_ref()
        #Reference<0.0.4.157>
        iex(11)> send(pid, {{:add, "event2", "this is an event", {{2218,04,02},{20,54,15}}}, repl_pid, msg_ref})
        {{:add, "event2", "this is an event", {{2218, 4, 2}, {20, 54, 15}}},
        #PID<0.118.0>, #Reference<0.0.4.157>}
        iex(12)> flush()
        {:ok, #Reference<0.0.4.157>}
        :ok
        iex(13)> msg_ref = make_ref()
        #Reference<0.0.4.170>
        iex(14)> send(pid, {{:cancel, "event2"}, repl_pid, msg_ref})
        {{:cancel, "event2"}, #PID<0.118.0>, #Reference<0.0.4.170>}
        iex(15)> flush()
        {:ok, #Reference<0.0.4.170>}
        :ok
    """
    def loop(state = %State{events: _events, clients: clients}) do
        receive do
            {{:subscribe, client}, pid, msg_ref} -> handle_subscribe(state, client, pid, msg_ref)
            {{:add, name, description, timeout}, pid, msg_ref} -> handle_add(state, name, description, timeout, pid, msg_ref)
            {{:cancel, name}, pid, msg_ref} -> handle_cancel(state, name, pid, msg_ref)
            {:done, name} -> handle_done(state, name)
            {:shutdown} -> exit(:shutdown)
            {:DOWN, ref, :process, _pid, _reason} -> loop(%{state | clients: Map.drop(clients, [ref])})
            {:code_change} -> Reminder.Server.loop(state)
            unknown  -> 
                Logger.info("Unknown message: #{inspect(unknown)}")
                loop(state)
        end
    end

    def handle_subscribe(state = %State{events: _events, clients: clients}, client, pid, msg_ref) do
        ref = Process.monitor(pid)
        newClients = Map.put(clients, ref, client)
        send(pid, {:ok, msg_ref})
        loop(%{state | clients: newClients})
    end

    def handle_add(state = %State{events: events, clients: _clients}, name, description, timeout, pid, msg_ref) do
        case valid_datetime(timeout) do
            true ->
                event_pid = Reminder.EventV2.start_link(self(), name, timeout)
                new_events = Map.put(events, name, %Event{name: name, description: description, pid: event_pid, timeout: timeout})
                send(pid, {:ok, msg_ref})
                loop(%{state | events: new_events})
            false ->
                send(pid, {:error, :bad_timeout, msg_ref})
                loop(state)
        end
    end

    def handle_cancel(state = %State{events: events, clients: _clients}, name, pid, msg_ref) do
        new_events = case Map.pop(events, name) do
            {event, new_events} ->  
                Reminder.EventV2.cancel(event.pid)
                new_events
            nil -> events
        end
        send(pid, {:ok, msg_ref})
        loop(%{state | events: new_events})
    end

    def handle_done(state = %State{events: events, clients: clients}, name) do
        case Map.pop(events, name) do
            {event, new_events} ->  
                send_to_clients({:done, event.name, event.description, "new code baby :)"}, clients)
                loop(%{state | events: new_events})
            nil -> 
                # This may happen if we cancel an event and
                # it fires at the same time
                loop(state)
        end
    end

    def send_to_clients(msg, clients) do
        Enum.each(clients, fn {_ref, pid} -> send(pid, msg) end)
    end

end