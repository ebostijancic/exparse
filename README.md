# exparse

XML parser for Elixir. Many parsers are built on top of `:xmerl` but it doesn't. It is pure Elixir.

For now it is a non-validating XML DOM parser. It supposes that the input is in proper format in UTF-8.

# Plans

* SAX parser implementation
* well-formedness validation
* entities
* file, url and encoding support
* XML 1.1
