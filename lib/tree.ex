
defmodule CirruParser.Tree do

  def appendItem(xs, level, buffer) when level == 0 do
    xs ++ [buffer]
  end

  def appendItem(xs, level, buffer) do
    res = appendItem (List.last xs), (level - 1), buffer
    init = Enum.take xs, length(xs) - 1
    init ++ [res]
  end

  defp nestingHelper(xs, n) when n <= 1 do
    xs
  end

  defp nestingHelper(xs, n) do
    nestingHelper xs, (n - 1)
  end

  def createNesting(n) do
    nestingHelper [], n
  end

  defp dollarHelper(before, listAfter) when listAfter == [] do
    before
  end

  defp dollarHelper(before, listAfter) do
    cursor = hd listAfter
    cond do
      (is_list cursor) ->
        chunk = resolveDollar cursor
        dollarHelper (before ++ [chunk]), (tl listAfter)
      (cursor.text == "$") ->
        chunk = resolveDollar (tl listAfter)
        before ++ [chunk]
      true ->
        chunk = before ++ [listAfter]
        dollarHelper chunk, (tl listAfter)
    end
  end

  def resolveDollar(xs) when xs == [] do
    xs
  end

  def resolveDollar(xs) do
    dollarHelper [], xs
  end

  defp commaHelper(before, listAfter) when listAfter == [] do
    before
  end

  defp commaHelper(before, listAfter) do
    cursor = hd listAfter
    if (is_list cursor) and (cursor != []) do
      head = hd cursor
      cond do
        (is_list head) ->
          chunk = resolveComma cursor
          commaHelper (before ++ [chunk]), (tl listAfter)
        (head.text == ",") ->
          chunk = resolveComma (tl cursor)
          commaHelper before, (chunk ++ (tl listAfter))
        true ->
          chunk = resolveComma cursor
          commaHelper (before ++ [chunk]), (tl listAfter)
      end
    else
      commaHelper (before ++ [cursor]), (tl listAfter)
    end
  end

  def resolveComma(xs) when xs == [] do
    xs
  end

  def resolveComma(xs) do
    commaHelper [], xs
  end

end
