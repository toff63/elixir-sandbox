defmodule Reminder.ServerV2 do
  require Logger

  defmodule State do
    defstruct events: [], clients: []
  end
  @type state :: %State{events: map(), clients: map()}

  defmodule Event do
    defstruct name: "", description: "", pid: "", timeout: {{1970, 01, 01}, {00, 00, 00}}
  end

  @doc """
  This version adds a client API so message format stays private

      iex(1)> Reminder.ServerV2.start_link()
      #PID<0.105.0>
      iex(2)> Reminder.ServerV2.subscribe(self())
      {:ok, #Reference<0.0.4.485>}
      iex(3)> Reminder.ServerV2.add_event( "event", "this is an event", {{2018,04,09},{21,53,50}})
      :ok
      iex(4)> flush
      {:done, "event", "this is an event"}
      :ok
      iex(5)> Reminder.ServerV2.add_event( "future_event", "this is an event", {{2030,04,09},{21,53,50}})
      :ok
      iex(6)> Reminder.ServerV2.cancel("future_event")
      :ok
  """

  @spec start() :: pid()
  def start() do
    pid = spawn(fn -> init() end)
    register(pid)
    pid
  end

  @spec start_link() :: pid()
  def start_link() do
    pid = spawn_link(fn -> init() end)
    register(pid)
    pid
  end

  def terminate() do
    send(server_pid(), {:shutdown})
  end

  @spec subscribe(pid()) :: {:ok, reference()}
  def subscribe(pid) do
    ref = Process.monitor(server_pid())
    send(server_pid(), {{:subscribe, pid}, self(), ref})

    receive do
      {:ok, ^ref} -> {:ok, ref}
      {:DOWN, _ref, :process, _pid, reason} -> {:error, reason}
    after
      5000 ->
        {:error, :timeout}
    end
  end

  @type date ::
          {{pos_integer(), pos_integer(), pos_integer()},
           {pos_integer(), pos_integer(), pos_integer()}}

  @spec add_event(String.t(), String.t(), date) :: any()
  def add_event(name, description, timeout) do
    ref = make_ref()
    send(server_pid(), {{:add, name, description, timeout}, self(), ref})

    receive do
      {msg, ^ref} -> msg
    after
      5000 ->
        {:error, :timeout}
    end
  end

  @spec cancel(String.t()) :: :ok
  def cancel(name) do
    ref = make_ref()
    send(server_pid(), {{:cancel, name}, self(), ref})

    receive do
      {:ok, ^ref} -> :ok
    after
      5000 ->
        {:error, :timeout}
    end
  end

  @spec listen(pos_integer()) :: [] | {:done, String.t(), String.t()}
  def listen(delay) do
    receive do
      m = {:done, _name, _description} -> [m | listen(0)]
    after
      delay ->
        []
    end
  end

  @spec server_pid() :: pid
  defp server_pid do
    Process.whereis(__MODULE__)
  end

  @spec register(pid) :: true
  defp register(pid) do
    Process.register(pid, __MODULE__)
  end

  defp init() do
    loop(%State{events: Map.new(), clients: Map.new()})
  end

  @spec valid_datetime(date) :: true | false
  defp valid_datetime(timeout = {{_, _, _}, {_, _, _}}) do
    case NaiveDateTime.from_erl(timeout) do
      {:ok, date} ->
        case NaiveDateTime.compare(date, NaiveDateTime.utc_now()) do
          :gt -> true
          _ -> false
        end

      {:error, _} ->
        false
    end
  end

  @spec loop(state) :: no_return
  defp loop(state = %State{events: _events, clients: clients}) do
    receive do
      {{:subscribe, client}, pid, msg_ref} ->
        handle_subscribe(state, client, pid, msg_ref)

      {{:add, name, description, timeout}, pid, msg_ref} ->
        handle_add(state, name, description, timeout, pid, msg_ref)

      {{:cancel, name}, pid, msg_ref} ->
        handle_cancel(state, name, pid, msg_ref)

      {:done, name} ->
        handle_done(state, name)

      {:shutdown} ->
        exit(:shutdown)

      {:DOWN, ref, :process, _pid, _reason} ->
        loop(%{state | clients: Map.drop(clients, [ref])})

      {:code_change} ->
        Reminder.ServerV2.loop(state)

      unknown ->
        Logger.info("Unknown message: #{inspect(unknown)}")
        loop(state)
    end
  end

  @spec handle_subscribe(state, String.t(), pid, reference) :: no_return()
  defp handle_subscribe(state = %State{events: _events, clients: clients}, client, pid, msg_ref) do
    ref = Process.monitor(pid)
    newClients = Map.put(clients, ref, client)
    send(pid, {:ok, msg_ref})
    loop(%{state | clients: newClients})
  end

  @spec handle_add(state, String.t(), String.t(), date, pid, reference) :: no_return()
  defp handle_add(
        state = %State{events: events, clients: _clients},
        name,
        description,
        timeout,
        pid,
        msg_ref
      ) do
    case valid_datetime(timeout) do
      true ->
        event_pid = Reminder.EventV2.start_link(server_pid(), name, timeout)

        new_events =
          Map.put(events, name, %Event{
            name: name,
            description: description,
            pid: event_pid,
            timeout: timeout
          })

        send(pid, {:ok, msg_ref})
        loop(%{state | events: new_events})

      false ->
        send(pid, {{:error, :bad_timeout}, msg_ref})
        loop(state)
    end
  end

  @spec handle_cancel(state, String.t(), pid, reference) :: no_return()
  defp handle_cancel(state = %State{events: events, clients: _clients}, name, pid, msg_ref) do
    new_events =
      case Map.pop(events, name) do
        {nil, events} ->
          events

        {event, new_events} ->
          Reminder.EventV2.cancel(event.pid)
          new_events
      end

    send(pid, {:ok, msg_ref})
    loop(%{state | events: new_events})
  end

  @spec handle_done(state, String.t()) :: no_return()
  defp handle_done(state = %State{events: events, clients: clients}, name) do
    case Map.pop(events, name) do
      {nil, _events} ->
        # This may happen if we cancel an event and
        # it fires at the same time
        loop(state)

      {event, new_events} ->
        send_to_clients({:done, event.name, event.description}, clients)
        loop(%{state | events: new_events})
    end
  end

  @spec send_to_clients(any(), map()) :: no_return()
  defp send_to_clients(msg, clients) do
    Enum.each(clients, fn {_ref, pid} -> send(pid, msg) end)
  end
end
