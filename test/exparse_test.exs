defmodule ExParseTest do
  use ExUnit.Case
  doctest ExParse

  test "empty root" do
    result = ExParse.parse ~s(<?xml version="1.0"?><empty/>)
    assert (length result) == 2
    assert {:empty_elem, "?xml", [{:attr, "version", "1.0"}]} in result
    assert {:empty_elem, "empty", []} in result
  end

  test "text content" do
    result = ExParse.parse ~s"""
      <?xml version="1.0" encoding="utf-8"?>
      <continent>
        <name>Europe</name>
        <countries>
          <country>
            <name>Hungary</name>
          </country>
          <country>
            <name>Spain</name>
          </country>
        </countries>
      </continent>
    """

    assert [_, _, europe, _] = result
    assert {:elem, "continent", [], c1} = europe
    assert {:elem, "name", [], [{:text, "Europe"}]} in c1
    assert [_, _, _, countries, _] = c1
    assert {:elem, "countries", [], [_, chun, _, cspain, _]} = countries
    assert {:elem, "country", [],
            [_, {:elem, "name", [], [{:text, "Hungary"}]}, _]} = chun
    assert {:elem, "country", [],
            [_, {:elem, "name", [], [{:text, "Spain"}]}, _]} = cspain
  end

  test "speed" do
    {ok, xml} = File.read "test/mondial.xml"
    t1 = :os.system_time :micro_seconds
    result = ExParse.parse xml
    t2 = :os.system_time :micro_seconds

    IO.puts "Microseconds #{t2 - t1}"
  end

end
