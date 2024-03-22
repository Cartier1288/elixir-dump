defmodule LRUCache do
  use Agent

  # have a map that points to a list node (that contains info about next and prev), have a list 
  # structure with a pointer to front and back.
  # on use, find the pointer to that node, extract it from middle of list, and append it to end
  # on overflow, get the front of the list and erase it from cache and list map.

  defstruct [:capacity, :history, cache: %{}, history_map: %{}]

  defp new(capacity) do
    %LRUCache{ capacity: capacity, history: LL.new() }
  end

  def start_link(capacity) do
    Agent.start_link(fn -> new(capacity) end, name: __MODULE__)
    # store history ?
    #
  end

  defp get_cache() 
  defp get_cache() do
    Agent.get(__MODULE__, & &1)
  end
  
  defp put_cache(lru)
  defp put_cache(lru) do
    Agent.update(__MODULE__, fn _ -> lru end)
  end

  @spec init_(capacity :: integer) :: any
  def init_(capacity) do
    case start_link(capacity) do
      {:error, {:already_started, pid}} -> (
        put_cache(new(capacity))
        {:ok, pid}
      )
      res -> res
    end
  end

  defp update_cache(lru, key, val)
  defp update_cache(
    %LRUCache{capacity: cap, cache: cache, history: history, history_map: hmap}, 
    key, val
  ) do
    cache = Map.put(cache, key, val)
    ref = hmap[key]
    {history, _} = LL.extract(history, ref)
    {history, ref} = LL.push_back(history, key)
    hmap = Map.put(hmap, key, ref)

    lru = %LRUCache{capacity: cap, cache: cache, history: history, history_map: hmap}
    put_cache(lru)
    lru
  end

  defp insert_cache(lru, key, val)
  defp insert_cache(
    %LRUCache{capacity: cap, cache: cache, history: history, history_map: hmap}, 
    key, val
  ) do
    cache = Map.put(cache, key, val)
    {history, ref} = LL.push_back(history, key)
    hmap = Map.put(hmap, key, ref)

    lru = %LRUCache{capacity: cap, cache: cache, history: history, history_map: hmap}
    put_cache(lru)
    lru
  end

  defp delete_cache(lru, key)
  defp delete_cache(
    %LRUCache{capacity: cap, cache: cache, history: history, history_map: hmap},
    key
  ) do
    ref = hmap[key]
    cache = Map.delete(cache, key)
    hmap = Map.delete(hmap, key)
    {history, _} = LL.extract(history, ref)

    lru = %LRUCache{capacity: cap, cache: cache, history: history, history_map: hmap}
    put_cache(lru)
    lru
  end

  @spec get(key :: integer) :: integer
  def get(key) do
    %LRUCache{cache: cache} = lru = get_cache()
    case Map.get(cache, key, nil) do
      nil -> -1
      val -> (
        update_cache(lru, key, val)
        val
      )
    end
  end

  @spec put(key :: integer, value :: integer) :: any
  def put(key, value) do
    %LRUCache{capacity: cap, history: history, history_map: hmap} = lru = get_cache()

    case Map.get(hmap, key, nil) do
      nil -> (
        {key, value}
        size = LL.size(history)
        cond do
          size > cap -> (
            elements = 
              LL.map(history, fn val -> val end)
              |> Enum.join(", ")

            raise "PANIC: LL size (#{size}) exceeds cap (#{cap}), elements: #{elements}"
          )
          size == cap -> ( # we are out of space, delete a row
            lru = delete_cache(lru, LL.front(history))
            insert_cache(lru, key, value)
            {key, value}
          )
          true -> ( # we haven't reached cap yet, can just insert
            insert_cache(lru, key, value)
            {key, value}
          )
        end
      )
      _ -> ( # we are updating a value, just rearrange history
        update_cache(lru, key, value)
        { key, value }
      )
    end
  end


  def execute(actions, args)
  def execute([], []), do: {:ok}
  def execute([action|actions], [arg|args]) do
    case action do
      "LRUCache" -> apply(__MODULE__, :init_, arg)
      "put" -> apply(__MODULE__, :put, arg)
      "get" -> apply(__MODULE__, :get, arg)
    end
    |> IO.inspect
    execute(actions, args)
  end
end

IO.inspect LRUCache.init_(2);
IO.inspect LRUCache.put(1, 1); # cache is {1=1}
IO.inspect LRUCache.put(2, 2); # cache is {1=1, 2=2}
IO.inspect LRUCache.get(1);    # return 1
IO.inspect LRUCache.put(3, 3); # LRU key was 2, evicts key 2, cache is {1=1, 3=3}
IO.inspect LRUCache.get(2);    # returns -1 (not found)
IO.inspect LRUCache.put(4, 4); # LRU key was 1, evicts key 1, cache is {4=4, 3=3}
IO.inspect LRUCache.get(1);    # return -1 (not found)
IO.inspect LRUCache.get(3);    # return 3
IO.inspect LRUCache.get(4);    # return 4


IO.inspect LRUCache.init_(1);
IO.inspect LRUCache.put(2,1);
IO.inspect LRUCache.get(2);
IO.inspect LRUCache.put(3,2);
IO.inspect LRUCache.get(2);
IO.inspect LRUCache.get(3);

IO.puts ""
IO.puts ""
LRUCache.execute(
  ["LRUCache","put","put","put","put","get","get","get","get","put","get","get","get","get","get"],
  [[3],[1,1],[2,2],[3,3],[4,4],[4],[3],[2],[1],[5,5],[1],[2],[3],[4],[5]]
)
