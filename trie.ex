# possible optimizations is to avoid creating one-off nodes, and match against a full string once
# there are no further branches

defmodule TrieNode do
  defstruct [complete: false, next: %{}]

  def insert(node, word)
  def insert(node, []), do: %TrieNode{node | complete: true}
  def insert(node = %TrieNode{next: next}, [c|word]) do
    next_c = Map.get(next, c, %TrieNode{})
    next_c = insert(next_c, word)
    next = Map.put(next, c, next_c)
    %TrieNode{node | next: next}
  end

  def match?(node, word)
  def match?(%TrieNode{complete: complete}, []), do: complete
  def match?(%TrieNode{next: next}, [c|word]) do
    if is_map_key(next, c) do
      TrieNode.match?(Map.get(next, c), word)
    else
      false
    end
  end

  defp reverse_str(word),
    do: word |> Enum.reverse |> List.to_string

  def partial_match?(trie, word, acc \\ [])
  def partial_match?(%TrieNode{complete: true}, [], acc), do: [{reverse_str(acc), []}]
  def partial_match?(_trie, [], _acc), do: []
  def partial_match?(%TrieNode{complete: complete, next: next}, [c|word], acc) do
    matches = if is_map_key(next, c),
      do: partial_match?(Map.get(next, c), word, [c|acc]),
      else: []

    if complete,
      do: [{reverse_str(acc), [c|word]}|matches],
      else: matches
  end
end

defmodule Trie do
  defstruct [head: %TrieNode{}]

  def new(words, acc \\ %Trie{})
  def new([], acc), do: acc
  def new([word|words], acc), do:
    new(words, add_word(acc, String.graphemes(word)))

  def add_word(trie, word)
  def add_word(trie = %Trie{head: head}, word), do: %Trie{trie | head: TrieNode.insert(head, word)}

  def match?(trie, word)
  def match?(%Trie{head: head}, word), do: TrieNode.match?(head, String.graphemes(word))

  # given a string, returns each prefix (and remaining string) that has a match
  # i.e., whenever a node with {completed: true} is reached, that is one valid prefix
  def partial_match?(trie, word)
  def partial_match?(%Trie{head: head}, word) when is_list(word),
    do: TrieNode.partial_match?(head, word)
  def partial_match?(%Trie{head: head}, word),
    do: TrieNode.partial_match?(head, String.graphemes(word))
end

trie = Trie.new(["hello", "help", "helping", "whatsittoya"])
IO.inspect trie
IO.inspect Trie.match? trie, "hello"
IO.inspect Trie.match? trie, "help"
IO.inspect Trie.match? trie, "whatsittoya"
IO.inspect Trie.match? trie, ""
IO.inspect Trie.match? trie, "hel"
IO.inspect Trie.match? trie, "zero"
IO.inspect Trie.match? trie, "whats"

IO.inspect Trie.partial_match? trie, "hellothere"
IO.inspect Trie.partial_match? trie, "helping"
