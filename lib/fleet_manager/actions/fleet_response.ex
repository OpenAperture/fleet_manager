defmodule OpenAperture.FleetManager.FleetAction.FleetResponse do

  @moduledoc """
  This module parses FleetApi structs into responses that can be understood across Components
  """  

  @doc """
  Method to convert a List of structs or single struct response into a list or single Maps response

  ## Options 

  The `response` option defines the list of FleetApi structs

  ## Return Value

  {:ok, response} | {:error, reason}
  """
	@spec parse(term) :: {:ok, term} | {:error, String.t}
	def parse(response) do
	  case response do
	    {:ok, values}    -> {:ok, parse_value(values)}
	    {:error, reason} -> {:error, reason}
	  end
	end

	@spec parse_value(list) :: list
	defp parse_value(raw_items) when is_list(raw_items) do
    Enum.reduce raw_items, [], fn(raw_item, items) ->
      case raw_item do
        nil -> items
        _   -> items ++ [parse_value(raw_item)]
      end
    end
	end

	@spec parse_value(term) :: term
	defp parse_value(raw_item) do
	  Map.from_struct(raw_item)
	end
end
