
Cirru Parser in Elixir
----

On Hex https://hex.pm/packages/cirru_parser/

```
{"cirru_parser", "~> 0.0.1"}
```

```elixir
require CirruParser
CirruParser.parse "code", "filename" => [["code"]]
```

APIs:

* `parse/2` returns tree with line infos, each leaf is a map
* `pare/2` returns tree without line infos, each leaf is a string

### License

MIT

