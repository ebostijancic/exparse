defmodule ExParse do
  @moduledoc """
    This module implements an XML parser in pure Elixir. The main entry
  point is the parse function which expects a unicode string.
  """

  @doc """
    Parses an XML document given by a string. The document should be
  well-formed and should be a proper XML document.
    string:  a string which contains the whole XML document
  It gives back a list containing
    * {:elem, name, attrlist, children}
    * {:empty_elem, name, attrlist}
    * {:text, text_value}
    * {:comment, text_value}
    * {:attr, name, value}
  It handles comments and cdata where cdata will be a text node.
  """
  def parse string do
    Enum.reverse start string
  end

  # TODO handle tab and newline as whitespace

  defp start << " ", rest :: binary >> do
    whitespace rest, :pi_start, []
  end
  defp start << "<?xml", rest :: binary >> do
    whitespace rest, :attr_name, [{:elem, "?xml"}]
  end

  defp whitespace << " ", rest :: binary >>, mode, context do
    whitespace rest, mode, context
  end
  defp whitespace << "\n", rest :: binary >>, mode, context do
    whitespace rest, mode, context
  end
  defp whitespace << "/>", rest :: binary >>, :in_start_element, context do
    content rest, "", attr_pack(context, true)
  end
  defp whitespace << "?>", rest :: binary >>, _mode, context do
    content rest, "", attr_pack(context, true)
  end
  defp whitespace << ">", rest :: binary >>, :in_start_element, context do
    content rest, "", attr_pack context
  end
  defp whitespace rest, :in_start_element, context do
    attr_name rest, "", context
  end
  defp whitespace rest, mode, context do
    case mode do
      :pi_start ->
        pi_start rest, context
      :attr_name ->
        attr_name rest, "", context
      :equal_sign ->
        equal_sign rest, context
      :attr_value ->
        attr_value rest, context
    end
  end

  defp pi_start << "<?xml", rest :: binary >>, context do
    whitespace rest, :attr_name, [{:elem, "?xml"} | context]
  end

  defp attr_name << "=", rest :: binary >>, name, context do
    whitespace rest, :attr_value, [{:attr, name} | context]
  end
  defp attr_name << " ", rest :: binary >>, name, context do
    whitespace rest, :equal_sign, [{:attr, name} | context]
  end
  defp attr_name << "?>", rest :: binary >>, _name, context do
    # we should fail here?
    content rest, "", attr_pack context
  end
  defp attr_name << ">", rest :: binary >>, _name, context do
    # we should fail here?
    content rest, "", attr_pack context
  end
  defp attr_name << ch :: binary-size(1), rest :: binary >>, name, context do
    attr_name rest, << name :: binary, ch :: binary-size(1) >>, context
  end

  defp equal_sign << "=", rest :: binary >>, context do
    whitespace rest, :attr_value, context
  end

  defp attr_value << "\"", rest :: binary >>, context do
    attr_value2 rest, "", "\"", context
  end
  defp attr_value << "'", rest :: binary >>, context do
    attr_value2 rest, "", "'", context
  end

  defp attr_value2 << "\"", rest :: binary >>, value, "\"", context do
    [{:attr, name} | ctx] = context
    whitespace rest, :in_start_element, [{:attr, name, value} | ctx]
  end
  defp attr_value2 << "'", rest :: binary >>, value, "'", context do
    [{:attr, name} | ctx] = context
    whitespace rest, :in_start_element, [{:attr, name, value} | ctx]
  end
  defp attr_value2 << ch :: binary-size(1), rest :: binary >>, value, terminator, context do
    attr_value2 rest, << value :: binary, ch :: binary-size(1) >>, terminator, context
  end

  # Add text if it is not empty
  defp add_text "", context do
    context
  end
  defp add_text text, context do
    [{:text, text} | context]
  end

  defp content "", text, context do
    add_text text, context
  end
  defp content << "</", rest :: binary >>, text, context do
    end_element rest, "", add_text(text, context)
  end
  defp content << "<!--", rest :: binary >>, text, context do
    comment rest, "", add_text(text, context)
  end
  defp content << "<![CDATA[", rest :: binary >>, text, context do
    cdata rest, "", add_text(text, context)
  end
  defp content << "<", rest :: binary >>, text, context do
    start_element rest, "", add_text(text, context)
  end
  defp content << ch :: binary-size(1), rest :: binary >>, text, context do
    content rest, << text :: binary, ch :: binary-size(1) >>, context
  end

  defp start_element << "/>", rest :: binary >>, name, context do
    content rest, "", attr_pack([{:elem, name} | context], true)
  end
  defp start_element << ">", rest :: binary >>, name, context do
    content rest, "", attr_pack [{:elem, name} | context]
  end
  defp start_element << " ", rest :: binary >>, name, context do
    whitespace rest, :attr_name, [{:elem, name} | context]
  end
  defp start_element << ch :: binary-size(1), rest :: binary >>, name, context do
    start_element rest, << name :: binary, ch :: binary-size(1) >>, context
  end

  defp end_element << ">", rest :: binary >>, _name, context do
    # check if the element name is the same
    content rest, "", elem_pack context
  end
  defp end_element << ch :: binary-size(1), rest :: binary >>, name, context do
    end_element rest, << name :: binary, ch :: binary-size(1) >>, context
  end

  defp comment << "-->", rest :: binary >>, text, context do
    content rest, "", [{:comment, text} | context]
  end
  defp comment << ch :: binary-size(1), rest :: binary >>, text, context do
    comment rest, << text :: binary, ch :: binary-size(1) >>, context
  end

  defp cdata << "]]>", rest :: binary >>, text, context do
    content rest, "", [{:text, text} | context]
  end
  defp cdata << ch :: binary-size(1), rest :: binary >>, text, context do
    cdata rest, << text :: binary, ch :: binary-size(1) >>, context
  end

  # Get the attributes and pack them to an element
  defp attr_pack context, empty \\ false do
    # Get the attributes collected since the last element
    {attrs, rest} = Enum.split_while context, fn {:attr, _, _} -> true
                                                 _ -> false
                                              end
    [{:elem, name} | rest2 ] = rest
    elem = case empty do
             false ->
               case name do
                 << "?", _ :: binary >> ->
                   :empty_elem
                 _ ->
                   :elem
               end
             true -> :empty_elem
           end
    [{elem, name, Enum.reverse attrs} | rest2]
  end

  defp elem_pack context do
    # Get all texts and empty elements since the last element
    {children, rest} = Enum.split_while context, fn {:elem, _, _} -> false
                                                    _ -> true
                                                 end
    [{:elem, name, attrs} | rest2] = rest
    [{:elem, name, attrs, Enum.reverse children} | rest2]
  end
end
