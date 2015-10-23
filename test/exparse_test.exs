defmodule ExParseTest do
  use ExUnit.Case
  doctest ExParse

  test "empty root" do
    result = ExParse.parse "<?xml version=\"1.0\"?><empty/>"
    assert {:elem, "?xml", [{:attr, "version", "1.0"}]} in result
  end
end
