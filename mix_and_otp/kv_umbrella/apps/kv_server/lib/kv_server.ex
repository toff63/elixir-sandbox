require Logger

defmodule KVServer do
  def accept(port) do
    :observer.start()

    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(KVServer.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  require IEx

  defp serve(socket) do
    msg = parse_and_execute_command(socket)
    write_line(socket, msg)
    serve(socket)
  end

  defp parse_and_execute_command(socket) do
    case read_line(socket) do
      {:ok, data} ->
        case KVServer.Command.parse(data) do
          {:ok, command} ->
            KVServer.Command.run(command)

          {:error, _} = err ->
            err
        end

      {:error, _} = err ->
        err
    end
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write_line(socket, {:ok, text}) do
    :gen_tcp.send(socket, text)
  end

  defp write_line(socket, {:error, :unknown_command}) do
    :gen_tcp.send(socket, "UNKNOWN COMMAND\r\n")
  end

  defp write_line(socket, {:error, error}) do
    # Unknown error. Write to the client and exit.
    :gen_tcp.send(socket, "ERROR\r\n")
    exit(error)
  end

  defp write_line(_socket, :closed) do
    # The connection was closed, exit politely.
    exit(:shutdown)
  end
end
