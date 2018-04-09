defmodule Reminder.EventServer do
  defmodule State do
    defstruct server: "", name: "", to_go: 0
  end

  @doc """
  This is a simple server that let you register reminders
  To test just run

      ied> parent = self()
      #PID<0.115.0>
      iex> spawn fn -> Reminder.EventServer.loop(%Reminder.EventServer.State{server: parent, name: "test", to_go: 5}) end
      #PID<0.106.0>
      iex> flush()
      :ok
      iex> flush()
      {:done, "test"}
      :ok
      iex> pid = spawn fn -> Reminder.EventServer.loop(%Reminder.EventServer.State{server: parent, name: "test", to_go: 500}) end
      #PID<0.122.0>
      iex> reply_ref = make_ref()
      #Reference<0.0.6.527>
      iex> send pid, {:cancel, self(), reply_ref}
      {:cancel, #PID<0.115.0>, #Reference<0.0.6.527>}
      iex> flush()
      {:ok, #Reference<0.0.6.527>}
      :ok
      iex> pid = spawn fn -> Reminder.EventServer.loop(%Reminder.EventServer.State{server: parent, name: "test", to_go: 365*24*60*60}) end
      #PID<0.127.0>
      iex>
      22:06:50.136 [error] Process #PID<0.127.0> raised an exception
      ** (ErlangError) Erlang error: :timeout_value
          (event_server) lib/event_server.ex:37: Reminder.EventServer.loop/1

  """
  def loop(%State{server: server, name: name, to_go: to_go}) do
    receive do
      {:cancel, server, ref} -> send(server, {:ok, ref})
    after
      to_go * 1000 -> send(server, {:done, name})
    end
  end
end
