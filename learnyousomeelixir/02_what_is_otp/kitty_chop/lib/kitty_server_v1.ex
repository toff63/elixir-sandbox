defmodule KittyServerv1 do
  require Logger

  @docmodule """
    iex(1)> pid = KittyServerv1.start_link()
    #PID<0.105.0>
    iex(2)> cat1 = KittyServerv1.order_cat(pid, "carl", "brown", "loves to burn bridges")
    %KittyServerv1.Cat{
    color: "brown",
    description: "loves to burn bridges",
    name: "carl"
    }
    iex(3)> KittyServerv1.return_cat(pid, cat1)
    :ok
    iex(4)> KittyServerv1.order_cat(pid, "jimmy", "orange", "cuddly")
    %KittyServerv1.Cat{
    color: "brown",
    description: "loves to burn bridges",
    name: "carl"
    }
    iex(5)> KittyServerv1.order_cat(pid, "jimmy", "orange", "cuddly")
    %KittyServerv1.Cat{color: "orange", description: "cuddly", name: "jimmy"}
    iex(6)> KittyServerv1.return_cat(pid, cat1)
    :ok
    iex(7)> KittyServerv1.close_shop(pid)

    20:06:58.965 [info]  %KittyServerv1.Cat{color: "brown", description: "loves to burn bridges", name: "carl"} was set free.

    :ok
    iex(8)> KittyServerv1.close_shop(pid)
    ** (EXIT from #PID<0.103.0>) shell process exited with reason: no process: the process is not alive or there's no process currently associated with the given name, possi
    bly because its application isn't started

    Interactive Elixir (1.6.1) - press Ctrl+C to exit (type h() ENTER for help)
  """
  defmodule Cat do
    defstruct name: "", color: "green", description: ""
  end

  # Client API

  def start_link() do
    spawn_link(fn -> init() end)
  end

  @doc """
  Synchronously orders a cat for you
  """
  @spec order_cat(pid, String.t(), String.t(), String.t()) :: Cat
  def order_cat(pid, name, color, description) do
    ref = Process.monitor(pid)
    send(pid, {{:order, name, color, description}, self(), ref})

    receive do
      {cat, ^ref} ->
        Process.demonitor(ref, [:flush])
        cat

      {:DOWN, ^ref, :process, _pid, reason} ->
        Process.exit(self(), reason)
    after
      5000 ->
        Process.exit(self(), :timeout)
    end
  end

  @doc """
  Asynchronously returns the cat
  """
  @spec return_cat(pid, Cat) :: atom
  def return_cat(pid, cat = %Cat{}) do
    send(pid, {:return, cat})
    :ok
  end

  @doc """
  Synchronously close the shop
  """
  @spec close_shop(pid) :: atom
  def close_shop(pid) do
    ref = Process.monitor(pid)
    send(pid, {:terminate, self(), ref})

    receive do
      {:ok, ^ref} ->
        Process.demonitor(ref, [:flush])
        :ok

      {:DOWN, ^ref, :process, _pid, reason} ->
        Process.exit(self(), reason)
    after
      5000 ->
        Process.exit(self(), :timeout)
    end
  end

  # Server fuctions

  def init() do
    loop([])
  end

  def loop(cats) do
    receive do
      {{:order, name, color, description}, pid, ref} ->
        # We need to empty the stock
        if cats === [] do
          send(pid, {%Cat{name: name, color: color, description: description}, ref})
          loop(cats)
        else
          send(pid, {hd(cats), ref})
          loop(tl(cats))
        end

      {:return, cat} ->
        loop([cat | cats])

      {:terminate, pid, ref} ->
        send(pid, {:ok, ref})
        terminate(cats)
    end
  end

  defp terminate(cats) do
    for cat <- cats, do: Logger.info("#{inspect(cat)} was set free.\n")
    :ok
  end
end
