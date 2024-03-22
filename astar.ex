defmodule AStar.Environment do
  @callback neighbours(env :: any(), el :: any()) :: any()
  @callback heuristic(env :: any(), el :: any()) :: any()
  @callback dist(env :: any(), el1 :: any(), el2 :: any()) :: any()
  @callback get_best(env :: any(), el :: any()) :: any()
  # returns whether or not it is better, the possibly updated environment, and the hscore of el2
  @callback check_best(env :: any(), el1 :: any(), el2 :: any()) :: { :best|:failed, any(), any() }
end

# a less weighted grid where the objective is to go top-left to bottom right always
defmodule AStar.Environment.WeightedGrid do
  alias AStar.Environment.WeightedGrid
  @behaviour AStar.Environment

  defstruct [:dimensions, :weights, :score]

  def flat_list_to_map(list, y, x \\ 0, acc \\ %{})
  def flat_list_to_map([], _y, _x, acc), do: acc
  def flat_list_to_map([v|list], y, x, acc),
    do: flat_list_to_map(list, y, x+1, Map.put(acc, {x,y}, v))

  def list_to_map(list, y \\ 0, acc \\ %{})
  def list_to_map([], _y, acc), do: acc
  def list_to_map([inner|list], y, acc),
    do: list_to_map(list, y+1, flat_list_to_map(inner, y, 0, acc))

  def new(width, height, weights) do
    dimensions = { width, height }

    # for y <- 1..width, x <- 1..height, reduce: Map.new() do
    #   acc -> Map.put(acc, {x,y}, :infinity)
    # end

    weight00 = Map.get(weights, {0,0})

    %WeightedGrid{
      dimensions: dimensions,
      weights: weights,
      score: Map.new() |> Map.put({0,0}, weight00)
    }
  end

  def neighbours(env, el)
  def neighbours(%WeightedGrid{dimensions: {width, height}}, {x, y}) do
    x1 = x+1
    y1 = y+1
    cond do
      x1 < width and y1 < height -> [{x+1, y}, {x, y+1}]
      x1 < width -> [{x1, y}]
      y1 < height -> [{x, y1}]
      true -> [] # goal ...
    end
  end

  def heuristic(env, el)
  def heuristic(_env, _el), do: 0

  # in this case, the distance is literally just the weight of the travelled to cell
  def dist(env, el1, el2)
  def dist(%WeightedGrid{weights: weights}, _el1, el2) do
    Map.get(weights, el2)
  end

  def get_best(env, el)
  def get_best(%WeightedGrid{score: score}, el), do: Map.get(score, el)

  def better?(tscore, score)
  def better?(_tscore, nil), do: true
  def better?(tscore, score), do: tscore < score

  def check_best(env, el1, el2)
  def check_best(env=%WeightedGrid{score: score}, el1, el2) do
    tscore = Map.get(score, el1) + dist(env, el1, el2)
    if better?(tscore, Map.get(score, el2)) do
      score = Map.put(score, el2, tscore)
      hscore = tscore+heuristic(env, el2)
      { :better, %WeightedGrid{ env | score: score }, hscore }
    else
      { :failed, env, }
    end
  end
end

defmodule AStar do
  alias AStar.Environment.WeightedGrid

  def qsearch(queue, goal, env)
  def qsearch(queue, goal, env) do
    {top, queue} = PrioQueue.pop(queue)
    case top do
      nil -> {:failed, env}
      {_key, ^goal} -> {:ok, env}
      {_key, el} -> (
        ns = WeightedGrid.neighbours(env, el)
        { queue, env } =
          for n <- ns, reduce: { queue, env } do
            { queue, env } -> (
              res = WeightedGrid.check_best(env, el, n)
              case res do
                { :better, env, hscore } -> { PrioQueue.insert(queue, n, hscore), env }
                { :failed, _ } -> { queue, env }
              end
            )
          end
        qsearch(queue, goal, env)
      )
      _ -> {:failed} # panic
    end
  end

  def search(start, goal, width, height, weights)
  def search(start, goal, width, height, weights) do
    weights = WeightedGrid.list_to_map(weights)
    queue = PrioQueue.insert(nil, start, Map.get(weights, start))
    env = WeightedGrid.new(width, height, weights)
    case qsearch(queue, goal, env) do
      { :failed, _env } -> {:failed}
      { :ok, env } -> {:ok, WeightedGrid.get_best(env, goal)}
    end
  end
end

IO.inspect AStar.search({0,0}, {2,2}, 3, 3, [[1,3,1],[1,5,1],[4,2,1]])
IO.inspect AStar.search({0,0}, {2,1}, 3, 2, [[1,2,3],[4,5,6]])
