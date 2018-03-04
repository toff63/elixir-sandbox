defmodule KVServerTest do
  use ExUnit.Case

  @moduletag :capture_log
  
  setup do
    Application.stop(:kv)
    :ok = Application.start(:kv)
  end

  setup do
    opts = [:binary, packet: :line, active: false]
    {:ok, socket} = :gen_tcp.connect('localhost', 4040, opts)
    %{socket: socket}
  end

  test "server interaction", %{socket: socket} do
    assert server_client(socket, "UNKOWN COMMAND\r\n") == "UNKNOWN COMMAND\r\n"
    assert server_client(socket, "GET SHOPPING eggs\r\n") == "NOT FOUND\r\n"
    assert server_client(socket, "CREATE SHOPPING\r\n") == "OK\r\n"
    assert server_client(socket, "PUT SHOPPING eggs 3\r\n") == "OK\r\n"
    assert server_client(socket, "GET SHOPPING eggs\r\n") == "3\r\n"
    assert server_client(socket, "") == "OK\r\n"
    assert server_client(socket, "DELETE SHOPPING eggs\r\n") == "OK\r\n"
    assert server_client(socket, "GET SHOPPING eggs\r\n") == "\r\n"
    assert server_client(socket, "") == "OK\r\n"
  end

  defp server_client(socket, request) do
    :ok = :gen_tcp.send(socket, request) 
    {:ok, data} = :gen_tcp.recv(socket, 0, 1000)
    data
  end
end
