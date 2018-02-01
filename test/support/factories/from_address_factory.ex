defmodule Explorer.FromAddressFactory do
  defmacro __using__(_opts) do
    quote do
      def from_address_factory do
        %Explorer.FromAddress{
          transaction: build(:transaction),
          address: build(:address),
        }
      end
    end
  end
end
