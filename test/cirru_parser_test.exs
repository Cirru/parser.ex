defmodule CirruParserTest do
  use ExUnit.Case
  require JSX

  Enum.map ["comma", "demo"], fn (name) ->
    test name do
      {_, code} = File.read "test/examples/#{:name}.cirru"
      {_, template} = File.read "text/ast/#{:name}.json"

      ast = CirruParser.pare code, ""
      {_, generated} = JSX.encode ast, [:space, {:indent, 2}]

      assert generated == template
    end
  end

end
