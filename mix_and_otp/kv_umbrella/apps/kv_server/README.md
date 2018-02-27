# KVServer

TCP server on top of the OTP server KV. It parses command line and call the KV server.

This is a demo app to learn how to design a distributed application using OTP. The details can be found on [Elixir web page](https://elixir-lang.org/getting-started/mix-otp/task-and-gen-tcp.html)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `kv_server` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:kv_server, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/kv_server](https://hexdocs.pm/kv_server).

