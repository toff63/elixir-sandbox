defmodule DBAgent do
  @moduledoc ~S"""
  DBAgent behave like an Agent but uses DBConnection to manage transactions

  ## Examples

  iex(1)> {:ok, agent} = DBAgent.start_link(fn() -> %{} end)
  iex(1)> is_pid(agent)
  true
  iex(2)> %{} = DBAgent.get(agent, &(&1))
  %{}
  iex(3)> :ok = DBAgent.update(agent, &Map.put(&1, :foo, :bar))
  :ok
  iex(4)> {:error, :oops} = DBAgent.transaction(agent, fn(conn) ->
  ...(4)>     :ok = DBAgent.update(conn, &Map.put(&1, :foo, :buzz))
  ...(4)>     :buzz = DBAgent.get(conn, &Map.fetch!(&1, :foo))
  ...(4)>     DBAgent.rollback(conn, :oops)
  ...(4)> end)
  {:error, :oops}                                                    
  iex(5)> :bar = DBAgent.get(agent, &Map.fetch!(&1, :foo))                                   
  :bar
  """

  @behaviour DBConnection

  defmodule Query do
    defstruct [:query]
  end

  defimpl DBConnection.Query, for: DBAgent.Query do
    def decode(_query, result, _opts), do: result
    def describe(query, _opts), do: IO.inspect(query)
    def encode(_query, params, _opts), do: {:query, params}
    def parse(query, _opts), do: query
  end

  def start_link(initial_value) when is_function(initial_value, 0) do
    DBConnection.start_link(__MODULE__, value: initial_value.())
  end

  def start_link(initial_value) do
    DBConnection.start_link(__MODULE__, value: initial_value)
  end

  def get(conn, fun, timeout \\ 5_000),
    do: DBConnection.execute!(conn, %Query{query: :get}, fun, timeout: timeout)

  def update(conn, fun, timeout \\ 5_000),
    do: DBConnection.execute!(conn, %Query{query: :update}, fun, timeout: timeout)

  def transaction(conn, fun, opts \\ []) when is_function(fun, 1),
    do: DBConnection.transaction(conn, fun, opts)

  def rollback(conn, reason), do: DBConnection.rollback(conn, reason)

  @impl true
  def connect(opts), do: {:ok, %{state: Keyword.get(opts, :value), status: :idle, rollback: nil}}

  @impl true
  def disconnect(_err, _state), do: :ok

  @impl true
  def checkin(state), do: {:ok, state}

  @impl true
  def checkout(state), do: {:ok, state}

  @impl true
  def ping(state), do: {:ok, state}

  @impl true
  def handle_execute(%Query{query: :get} = query, {:query, fun}, _opts, state) do
    {:ok, query, fun.(state.state), state}
  end

  @impl true
  def handle_execute(%Query{query: :update} = query, {:query, fun}, _opts, state) do
    state = Map.put(state, :state, fun.(state.state))
    {:ok, query, :ok, state}
  end

  @impl true
  def handle_begin(_opts, %{status: :idle, state: state} = s) do
    {:ok, :began, %{s | status: :transaction, rollback: state}}
  end

  @impl true
  def handle_commit(_opts, %{status: :transaction} = s) do
    {:ok, :ok, %{s | status: :idle, rollback: nil}}
  end

  @impl true
  def handle_rollback(_opts, %{status: :transaction, rollback: previous_state}) do
    {:ok, :whatever, %{status: :idle, state: previous_state, rollback: nil}}
  end

  @impl true
  def handle_close(_query, _opts, %{status: :prepared} = s), do: {:ok, :ok, s}

  @impl true
  def handle_prepare(_query, _opts, %{status: :idle} = s),
    do: {:ok, :ok, %{s | status: :prepared}}

  @impl true
  def handle_deallocate(_query, _cursor, _opts, s), do: {:ok, :ok, s}

  @impl true
  def handle_declare(_query, _cursor, _opts, s), do: {:ok, :ok, s}

  @impl true
  def handle_fetch(_query, _cursor, _opts, s), do: {:cont, :ok, s}

  @impl true
  def handle_status(_opts, %{status: :transaction} = s), do: {:transaction, s}
  def handle_status(_opts, s), do: {:idle, s}
end
