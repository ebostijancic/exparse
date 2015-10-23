defmodule ExParseTest do
  use ExUnit.Case
  doctest ExParse

  test "empty root" do
    result = ExParse.parse ~s(<?xml version="1.0"?><empty/>)
    assert (length result) == 2
    assert {:elem, "?xml", [{:attr, "version", "1.0"}]} in result
  end
end
