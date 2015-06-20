defmodule CirruParserTest do
  use ExUnit.Case
  require JSX

  defp readFileFor(name) do
    {_, template} = File.read "test/ast/#{name}.json"
    template
  end

  defp generateFor(name) do
    {_, code} = File.read "test/examples/#{name}.cirru"

    ast = CirruParser.pare code, ""
    {_, generated} = JSX.encode ast, [:space, {:indent, 2}]
    generated
  end

  test "all demos" do
    allCases = [
      "comma", "demo", "folding", "html",
      "indent", "line", "parentheses",
      "quote", "spaces", "unfolding"
    ]
    Enum.map allCases, fn (name) ->
      template = String.strip (readFileFor name)
      generated = String.strip (generateFor name)
      assert generated == template
    end
  end

end