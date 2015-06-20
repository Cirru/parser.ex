defmodule CirruParser do

  require CirruParser.Tree
  alias CirruParser.Tree

  def parse(code, filename) do
    buffer = nil
    state = %{
      :name => :indent,
      :x => 1,
      :y => 2,
      :level => 1,
      :indent => 0,
      :indented => 0,
      :nest => 0,
      :path => filename,
    }

    res = parseRunner [], buffer, state, code
    res = Enum.map res, fn (item) -> Tree.resolveDollar item end
    res = Enum.map res, fn (item) -> Tree.resolveComma item end
    res
  end

  defp shorten(xs) when is_list xs do
    Enum.map xs, fn (item) -> shorten item end
  end

  defp shorten(xs) do
    xs.text
  end

  def pare(code, filename) do
    res = parse code, filename
    shorten res
  end

  # eof

  defp escape_eof(_, _, _, _) do
    raise "EOF in escape state"
  end

  defp string_eof(_, _, _, _) do
    raise "EOF in string state"
  end

  def space_eof(xs, _, _, _) do
    xs
  end

  defp token_eof(xs, buffer, state, _) do
    buffer = %{buffer | :ex => state.x, :ey => state.y}
    xs = Tree.appendItem xs, state.level, buffer
    xs
  end

  defp indent_eof(xs, _, _, _) do
    xs
  end

  # escape

  defp escape_newline(_, _, _, _) do
    raise "new line while space"
  end

  defp escape_n(xs, buffer, state, code) do
    state = %{state | :x => 1, :name => :string}
    buffer = %{buffer | :name => buffer.x <> "\n"}
    parseRunner xs, buffer, state, code
  end

  defp escape_t(xs, buffer, state, code) do
    state = %{state | :x => state.x + 1, :name => :string}
    buffer = %{buffer | :text => buffer.text <> "\t"}
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  defp escape_else(xs, buffer, state, code) do
    state = %{state | :x => state.x + 1, :name => :string}
    buffer = %{buffer | :text => buffer.text <> (String.first code)}
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  # string

  defp string_backslash(xs, buffer, state, code) do
    state = %{state | :name => :token_eof, :x => state.x + 1}
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  defp string_newline(_, _, _, _) do
    raise "newline in a string"
  end

  defp string_quote(xs, buffer, state, code) do
    state = %{state | :name => :token, :x => state.x + 1}
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  defp string_else(xs, buffer, state, code) do
    state = %{state | :x => state.x + 1}
    buffer = %{buffer | :text => buffer.text <> (String.first code)}
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  # space

  defp space_space(xs, buffer, state, code) do
    state = %{state | :state => state.x + 1}
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  defp space_newline(xs, buffer, state, code) do
    if state.nest != 0 do
      raise "incorrect nesting"
    end
    state = %{state | :name => :indent, :x => 1,
      :y => state.y + 1, :indented => 0
    }
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  defp space_open(xs, buffer, state, code) do
    nesting = Tree.createNesting 1
    xs = Tree.appendItem xs, state.level, nesting
    state = %{state | :nest => state.nest + 1,
      :level => state.level + 1, :x => state.x + 1
    }
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  defp space_close(xs, buffer, state, code) do
    state = %{state | :nest => state.nest - 1,
      :level => state.level - 1,
      :x => state.x + 1
    }
    if state.nest < 0 do
      raise "close at space"
    end
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  defp space_quote(xs, _, state, code) do
    buffer = %{:text => "",
      :x => state.x, :y => state.y,
      :ex => state.x, :ey => state.y,
      :path => state.parseRunner
    }
    state = %{state | :name => :string, :x => state.x + 1}

    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  defp space_else(xs, _, state, code) do
    buffer = %{:text => (String.first code),
      :x => state.x, :y => state.y,
      :ex => state.x, :ey => state.y,
      :path => state.path
    }
    state = %{state | :name => :token, :x => state.x + 1}
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  # token

  defp token_space(xs, buffer, state, code) do
    buffer = %{buffer | :ex => state.x, :ey => state.y}
    xs = Tree.appendItem xs, state.level, buffer
    state = %{state | :name => :space, :x => state.x + 1}
    buffer = nil
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  defp token_newline(xs, buffer, state, code) do
    buffer = %{buffer | :ex => state.x, :ey => state.y}
    xs = Tree.appendItem xs, state.level, buffer
    state = %{state | :name => :indent,
      :indented => 0, :x => 1, :y => state.y + 1
    }
    buffer = nil
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  defp token_open(_, _, _, _) do
    raise "open parenthesis in token"
  end

  defp token_close(xs, buffer, state, code) do
    buffer = %{buffer | :ex => state.x, :ey => state.y}
    xs = Tree.appendItem xs, state.level, buffer
    state = %{state | :name => :space}
    buffer = nil
    parseRunner xs, buffer, state, code
  end

  defp token_quote(xs, buffer, state, code) do
    state = %{state | :name => :string, :x => state.x + 1}
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  defp token_else(xs, buffer, state, code) do
    buffer = %{buffer | :text => buffer.text <> (String.first code)}
    state = %{state | :x => state.x + 1}
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  # indent

  defp indent_space(xs, buffer, state, code) do
    state = %{state | :indented => state.indented + 1, :x => state.x + 1}
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  defp indent_newline(xs, buffer, state, code) do
    state = %{state | :x => 1, :y => state.y + 1, :indented => 0}
    parseRunner xs, buffer, state, (String.slice code, 1..-1)
  end

  defp indent_close(_, _, _, _) do
    raise "close parenthesis at indent"
  end

  defp indent_else(xs, buffer, state, code) do
    if (rem state.indented, 2) == 1 do
      raise "odd indentation"
    end

    indented = state.indented / 2
    diff = indented - state.indent

    cond do
      (diff <= 0) ->
        nesting = Tree.createNesting 1
        xs = Tree.appendItem xs, (state.level + diff - 1), nesting
      (diff > 0) ->
        nesting = Tree.createNesting diff
        xs = Tree.appendItem xs, state.level, nesting
    end

    state = %{state | :name => :space,
      :level => state.level + diff, :indent => state.indented
    }
    parseRunner xs, buffer, state, code
  end

  # parse

  defp parseRunner(xs, buffer, state, code) do
    if String.length(code) == 0 do
      eof = true
    else
      eof = false
      char = String.first code
    end

    case state.name do
      :escape ->
        cond do
          eof ->
            escape_eof xs, buffer, state, code
          (char == "\n") ->
            escape_newline xs, buffer, state, code
          (char == "n") ->
            escape_n xs, buffer, state, code
          (char == "t") ->
            escape_t xs, buffer, state, code
          true ->
            escape_else xs, buffer, state, code
        end
      :string ->
        cond do
          eof ->
            string_eof xs, buffer, state, code
          (char == "\\") ->
            string_backslash xs, buffer, state, code
          (char == "\n") ->
            string_newline xs, buffer, state, code
          (char == "\"") ->
            string_quote xs, buffer, state, code
          true ->
            string_else xs, buffer, state, code
        end
      :space ->
        cond do
          eof ->
            space_eof xs, buffer, state, code
          (char == " ") ->
            space_space xs, buffer, state, code
          (char == "\n") ->
            space_newline xs, buffer, state, code
          (char == "(") ->
            space_open xs, buffer, state, code
          (char == ")") ->
            space_close xs, buffer, state, code
          (char == "\"") ->
            space_quote xs, buffer, state, code
          true ->
            space_else xs, buffer, state, code
        end
      :token ->
        cond do
          eof ->
            token_eof xs, buffer, state, code
          (char == " ") ->
            token_space xs, buffer, state, code
          (char == "\n") ->
            token_newline xs, buffer, state, code
          (char == "(") ->
            token_open xs, buffer, state, code
          (char == ")") ->
            token_close xs, buffer, state, code
          (char == "\"") ->
            token_quote xs, buffer, state, code
          true ->
            token_else xs, buffer, state, code
        end
      :indent ->
        cond do
          eof ->
            indent_eof xs, buffer, state, code
          (char == " ") ->
            indent_space xs, buffer, state, code
          (char == "\n") ->
            indent_newline xs, buffer, state, code
          (char == ")") ->
            indent_close xs, buffer, state, code
          true ->
            indent_else xs, buffer, state, code
        end
    end
  end
end
