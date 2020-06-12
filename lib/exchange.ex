defmodule Exchange do
  @moduledoc false

  @type event :: %{
    instruction: :new | :update | :delete,
    side: :bid | :ask,
    price_level_index: integer(),
    price: float(),
    quantity: integer()
  }

  @type book :: %{
    bid_price: float(),
    bid_quantity: integer(),
    ask_price: float(),
    ask_quantity: integer()
  }

  def start_link() do
    Agent.start_link(fn -> [] end)
  end

  @spec send_instruction(exchange :: pid(), event :: event()) :: :ok | {:error, any()}
  def send_instruction(exchange, event) do
    Agent.update(exchange, fn state -> handle_event(state, event) end)
  end

  @spec order_book(exchange :: pid(), book_depth :: integer()) :: list(book())
  def order_book(exchange, book_depth) do
    Agent.get(exchange, fn store ->
      store
      |> Enum.take_while(fn {key, _} -> key <= book_depth end)
      |> Enum.map(fn {_key, book} ->
        %{
          ask_price: book.ask.price,
          ask_quantity: book.ask.quantity,
          bid_price: book.bid.price,
          bid_quantity: book.bid.quantity
        }
      end)
    end)
  end

  defp handle_event(store, %{instruction: :new} = params), do: insert(store, params)

  defp handle_event(store, %{instruction: :delete, price_level_index: price_level}) do
    delete(store, price_level)
  end

  defp handle_event(store, params), do: update(store, params)

  defp insert(store, params) do
    key = params.price_level_index
    {take, to_shift} = Enum.split(store, key - 1)
    value = Map.put(init_book(), params.side, %{price: params.price, quantity: params.quantity})
    shifted = Enum.map(to_shift, fn {price_level, v} -> {price_level + 1, v} end)

    take ++ [{key, value}] ++ shifted
  end

  defp delete(store, price_level, acc \\ [])

  defp delete([], _price_level, _acc), do: {:error, :not_found}

  defp delete([{key, _} | rest], price_level, acc) when key == price_level do
    {:ok, Enum.reverse(acc) ++ Enum.map(rest, fn {price_level, v} -> {price_level - 1, v} end)}
  end

  defp delete([item | rest], price_level, acc), do: delete(rest, price_level, [item | acc])

  defp update(store, params) do
    key = params.price_level_index
    store = Map.new(store)

    if Map.has_key?(store, key) do
      Map.update!(store, key, fn book ->
        Map.put(book, params.side, %{price: params.price, quantity: params.quantity})
      end)
    else
      {:error, :not_found}
    end
  end

  defp init_book, do: %{bid: %{price: 0, quantity: 0}, ask: %{price: 0, quantity: 0}}
end
