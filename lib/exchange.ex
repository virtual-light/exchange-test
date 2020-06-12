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
      store = Map.new(store)

      for key <- 1..book_depth do
        book = Map.get(store, key, %{})
        get_book_info(book)
      end
    end)
  end

  defp handle_event(store, %{instruction: :new} = params), do: insert(store, params)

  defp handle_event(store, %{instruction: :delete, price_level_index: price_level}) do
    delete(store, price_level)
  end

  defp handle_event(store, params), do: update(store, params)

  defp insert(store, params) do
    key = params.price_level_index
    side = params.side
    side_params = %{price: params.price, quantity: params.quantity}

    {lower, rest} = Enum.split_while(store, fn {price_level, _} -> price_level < key end)

    if Enum.empty?(rest) do
      lower ++ [{key, Map.put(%{}, side, side_params)}]
    else
      {first_key, book} = List.first(rest)

      if first_key == key and is_nil(Map.get(book, side)) do
        List.delete_at(lower, -1) ++ [{key, Map.put(book, side, side_params)}] ++ rest
      else
        shifted = Enum.map(rest, fn {price_level, v} -> {price_level + 1, v} end)
        lower ++ [{key, Map.put(%{}, side, side_params)}] ++ shifted
      end
    end
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

  defp get_book_info(book) do
    bid_side = Map.get(book, :bid, %{price: 0, quantity: 0.0})
    ask_side = Map.get(book, :ask, %{price: 0, quantity: 0.0})

    %{
      ask_price: ask_side.price,
      ask_quantity: ask_side.quantity,
      bid_price: bid_side.price,
      bid_quantity: bid_side.quantity
    }
  end
end
