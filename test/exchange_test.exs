defmodule ExchangeTest do
  use ExUnit.Case
  doctest Exchange

  test "example test" do
    {:ok, exchange_pid} = Exchange.start_link()

    Exchange.send_instruction(exchange_pid, %{
      instruction: :new,
      side: :bid,
      price_level_index: 1,
      price: 50.0,
      quantity: 30
    })

    Exchange.send_instruction(exchange_pid, %{
      instruction: :new,
      side: :bid,
      price_level_index: 2,
      price: 40.0,
      quantity: 40
    })

    Exchange.send_instruction(exchange_pid, %{
      instruction: :new,
      side: :ask,
      price_level_index: 1,
      price: 60.0,
      quantity: 10
    })

    Exchange.send_instruction(exchange_pid, %{
      instruction: :new,
      side: :ask,
      price_level_index: 2,
      price: 70.0,
      quantity: 10
    })

    Exchange.send_instruction(exchange_pid, %{
      instruction: :update,
      side: :ask,
      price_level_index: 2,
      price: 70.0,
      quantity: 20
    })

    Exchange.send_instruction(exchange_pid, %{
      instruction: :update,
      side: :bid,
      price_level_index: 1,
      price: 50.0,
      quantity: 40
    })

    expected = [
      %{ask_price: 60.0, ask_quantity: 10, bid_price: 50.0, bid_quantity: 40},
      %{ask_price: 70.0, ask_quantity: 20, bid_price: 40.0, bid_quantity: 40}
    ]

    assert  Exchange.order_book(exchange_pid, 2) == expected
  end
end
