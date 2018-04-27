defmodule KittyServerv2 do
  require Logger

  defmodule Cat do
    defstruct name: "", color: "green", description: ""
  end

  # Client API

  def start_link() do
    MyServer.start_link(__MODULE__, [])
  end

  # Synchronous call
  @spec order_cat(pid, String.t(), String.t(), String.t()) :: Cat
  def order_cat(pid, name, color, description) do
    MyServer.call(pid, {:order, name, color, description})
  end

  @doc """
  Asynchronously returns the cat
  """
  @spec return_cat(pid, Cat) :: atom
  def return_cat(pid, cat = %Cat{}) do
    MyServer.cast(pid, {:return, cat})
  end

  @spec close_shop(pid) :: atom
  def close_shop(pid) do
    MyServer.call(pid, :terminate)
  end

  def handle_call({:order, name, color, description}, from, cats) do
    # We need to empty the stock
    if cats === [] do
      MyServer.reply(%Cat{name: name, color: color, description: description}, from)
      cats
    else
      MyServer.reply(hd(cats), from)
      tl(cats)
    end
  end

  def handle_call(:terminate, from, cats) do
    MyServer.reply(:ok, from)
    terminate(cats)
  end

  def handle_cast({:return, cat}, cats) do
    [cat | cats]
  end

  defp terminate(cats) do
    for cat <- cats, do: Logger.info("#{inspect(cat)} was set free.\n")
    exit(:normal)
  end
end
