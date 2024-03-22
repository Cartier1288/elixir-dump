defmodule LLNode do
  defstruct [:value, prev: nil, next: nil]
end

defmodule LL do
  defstruct [:table, size: 0, head: nil, tail: nil]

  def new
  def new() do
    table = :ets.new(:doubly_linked_list, [:set, :public])
    %LL{table: table}
  end

  # creates a new node in the table, but doesn't perform any linking, and doesn't officially add it
  # to the list
  defp new_node(table, value)
  defp new_node(table, value) do
    ref = make_ref()
    :ets.insert(table, {ref, %LLNode{value: value}})
    ref
  end

  defp get_node(table, ref) do
    [{_, node}] = :ets.lookup(table, ref)
    node
  end

  defp update_node(table, ref, node) do
    :ets.insert(table, {ref, node})
  end

  defp delete_node(table, ref) do
    :ets.delete(table, ref)
  end

  defp link(table, from, to)
  defp link(table, nil, nil), do: table
  defp link(table, from, nil) do
    from_node = get_node(table, from)
    update_node(table, from, %LLNode{from_node | next: nil})
    table
  end
  defp link(table, nil, to) do
    to_node = get_node(table, to)
    update_node(table,   to, %LLNode{  to_node | prev: nil})
    table
  end
  defp link(table, from, to) do
    from_node = get_node(table, from)
    to_node = get_node(table, to)

    update_node(table, from, %LLNode{from_node | next: to})
    update_node(table,   to, %LLNode{  to_node | prev: from})
    
    table
  end

  # returns a modified table and the ref to the node
  def push_back(list, value)
  def push_back(%LL{table: table, size: size, head: head, tail: tail}, value) do
    ref = new_node(table, value)
    size = size+1
    case head do
      nil -> { %LL{table: table, size: size, head: ref, tail: ref}, ref }
      _ -> (
        link(table, tail, ref)
        { %LL{table: table, size: size, head: head, tail: ref}, ref }
      )
    end
  end

  # returns the updated list and the value of the extracted node
  def extract(list, ref)
  def extract(list = %LL{table: table, size: size, head: head, tail: tail}, ref) do
    %LLNode{value: val, prev: prev, next: next} = get_node(table, ref)
    delete_node(table, ref)
    size = size-1

    link(table, prev, next)

    # if we are extracting head/tail, we need to update the new head/tail
    list = 
      case {head, tail, ref} do
        {ref, ref, ref} -> %LL{table: table, size: size, head: nil, tail: nil}
        {head, _, head} -> %LL{table: table, size: size, head: next, tail: tail}
        {_, tail, tail} -> %LL{table: table, size: size, head: head, tail: prev}
        _ -> list
      end

    { list, val }
  end

  def front(list)
  def front(%LL{table: table, head: head}) do
    %LLNode{value: val} = get_node(table, head)
    val
  end

  def back(list)
  def back(%LL{table: table, tail: tail}) do
    %LLNode{value: val} = get_node(table, tail)
    val
  end

  defp _map(table, node, f)
  defp _map(_table, nil, _f), do: []
  defp _map(table, node, f) do
    %LLNode{value: val, next: next} = get_node(table, node)
    [f.(val) | _map(table, next, f)]
  end

  def map(list, f)
  def map(%LL{table: table, head: head}, f), do: _map(table, head, f)

  def size(list)
  def size(%LL{size: size}), do: size
end

list = LL.new()
{list, one} = LL.push_back(list,1)
{list, _} = LL.push_back(list,2)
{list, _} = LL.push_back(list,3)
{list, four} = LL.push_back(list,4)
{list, _} = LL.push_back(list,5)
{list, _} = LL.push_back(list,6)
{list, _} = LL.push_back(list,7)
{list, eight} = LL.push_back(list,8)
IO.inspect LL.size(list)
IO.inspect LL.map(list, & &1)
{list, val} = LL.extract(list, four)
IO.inspect val

IO.puts ""
{list, val} = LL.extract(list, one)
IO.inspect val
IO.inspect LL.size(list)
IO.inspect LL.map(list, & &1)
IO.inspect LL.front(list)
IO.inspect LL.back(list)

IO.puts ""
{list, val} = LL.extract(list, eight)
IO.inspect val
IO.inspect LL.size(list)
IO.inspect LL.map(list, & &1)
IO.inspect LL.front(list)
IO.inspect LL.back(list)
