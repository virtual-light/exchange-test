defmodule Exchange.StoreKeeper do
  use GenServer

  @impl GenServer
  def init(:ok), do: {:ok, []}

  @impl GenServer
  def handle_call({:handle_event, event}, _from, state) do
    case Exchange.handle_event(state, event) do
      {:ok, new_state} ->
        {:reply, :ok, new_state}

      error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call(:get_store, _from, state) do
    {:reply, state, state}
  end
end
