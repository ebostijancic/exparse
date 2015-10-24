## exparse

XML parser for Elixir. Many parsers are built on top of `:xmerl` but it doesn't. It is pure Elixir.

For now it is a non-validating XML DOM parser. It supposes that the input is in proper format in UTF-8.

## Usage

Right now it parses from UTF-8 string (binary). I don't plan to support character lists for efficiency reasons.

```elixir
ExParser.string ~s(<?xml version="1.0"?><root/>)
```

The parse speed of a 1.7MB XML file is

| Date   |  Speed |
| -------|--------|
| 2015-10-24  |   450ms |

## Plans

* SAX parser implementation
* well-formedness validation
* entities
* file, url and encoding support
* XML 1.1
