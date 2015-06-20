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

  test "on single task" do
    name = "line"
    template = readFileFor name
    generated = generateFor name
    IO.puts generated
    IO.puts template
    assert generated == template
  end

end
