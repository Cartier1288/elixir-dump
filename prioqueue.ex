defmodule LeftistTree do
  # element, rank, left, right
  defstruct [:element, :key, rank: 0, left: nil, right: nil]
end

defmodule PrioQueue do
  def find_rank(right)
  def find_rank(nil), do: 0
  def find_rank(%LeftistTree{rank: rank}), do: rank+1

  # enforces the LeftistTree invariant that rank(right) < rank(left)
  def enforce(left, right)
  def enforce(left, nil), do: { left, nil }
  def enforce(nil, right), do: { right, nil }
  def enforce(left = %LeftistTree{rank: r1}, right = %LeftistTree{rank: r2})
    when r1<r2, do: { right, left }
  def enforce(left, right), do: { left, right }

  def merge(tree1, tree2)
  def merge(nil, nil), do: nil
  def merge(tree1, nil), do: tree1
  def merge(nil, tree2), do: tree2
  def merge(
    tree1 = %LeftistTree{element: e1, key: key1, rank: r1, left: left1, right: right1},
    tree2 = %LeftistTree{element: e2, key: key2, rank: r2, left: left2, right: right2}
  ) when key1 <= key2 do
    right1 = merge(right1, tree2)
    { left, right } = enforce(left1, right1) # swap if rank(left) < rank(right)
    %LeftistTree{element: e1, key: key1, rank: find_rank(right), left: left, right: right}
  end
  def merge(tree1, tree2), do: merge(tree2, tree1)

  def insert(tree, el, key)
  def insert(tree, el, key) do
    merge(tree, %LeftistTree{element: el, key: key})
  end

  # deletes the max element from the tree and returns its value
  def pop(tree)
  def pop(nil), do: { nil, nil}
  def pop(%LeftistTree{element: el, key: key, left: left, right: right}),
    do: {{key, el}, merge(left, right)}


  def draw_line(tree1, tree2)
  def draw_line(_, nil), do: ""
  def draw_line(nil, _), do: ""
  def draw_line(%LeftistTree{element: el1}, %LeftistTree{element: el2}) do
    "\"#{el1}\" -> \"#{el2}\";"
  end

  def idot(tree)
  def idot(nil), do: ""
  def idot(root=%LeftistTree{element: el, key: key, rank: rank, left: left, right: right}) do
    """
      "#{el}" [label="#{el}(key=#{key}, rank=#{rank})"]
      #{draw_line(root, left)}#{draw_line(root, right)}
      #{idot(left)}#{idot(right)}
    """
  end

  def dot(tree, name \\ "dotgraph")
  def dot(tree, name) do
    """
    digraph "#{name}" {
    #{idot(tree)}
    }
    """
  end

end

PrioQueue.insert(nil, "a", 1)
|> PrioQueue.insert("b", 2)
|> PrioQueue.insert("c", 3)
|> PrioQueue.insert("d", 4)
|> PrioQueue.insert("e", 5)
|> PrioQueue.insert("f", 6)
|> PrioQueue.insert("g", 7)
|> PrioQueue.insert("h", 8)
|> PrioQueue.insert("i", 9)
|> PrioQueue.insert("j", 10)
|> PrioQueue.insert("k", 11)
|> PrioQueue.insert("l", 0)
|> PrioQueue.dot
|> IO.puts
