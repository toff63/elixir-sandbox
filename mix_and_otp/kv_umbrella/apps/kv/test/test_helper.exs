exclude = if Node.alive?, do: [], else: [distributed_toto: true]
ExUnit.start(exclude: exclude)