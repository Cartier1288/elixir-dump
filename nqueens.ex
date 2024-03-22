defmodule Solution do
  # solves n-queens using AC-3 + backtracking search

  @spec solve_n_queens(n :: integer) :: [[String.t]]
  def solve_n_queens(n) do
    arcs = create_arcs(n, n)
    domains = create_domains(n, n)
    search(n, arcs, domains)
  end

  def unique_solution(sln) do
    for {_,d} <- sln, reduce: true do
      acc -> acc and (case d do
        [_] -> true
        _ -> false
      end)
    end
  end

  def solution_to_list(domains) do
    (for { k, [v] } <- domains, do: { k, v })
    |> Enum.sort
    |> Enum.map(fn {_, v} -> v end)
  end

  def search(n, arcs, domains, idx \\ 1)
  def search(n, _arcs, _domains, idx) when idx > n, do: []
  def search(n, arcs, domains, idx) do
    for r <- domains[idx], reduce: [] do
     acc -> (
        domains = Map.put(domains, idx, [r])
        case solve(arcs, domains, n) do
          {:failed, _} -> acc
          {:ok, sln} -> acc ++ (
            cond do
              unique_solution(sln) -> [solution_to_list(sln)]
              true -> search(n, arcs, sln, idx+1)
            end
          )
        end
     )
   end
  end

  # creates n(n-1) arcs
  def create_arcs(n, idx)
  def create_arcs(_, 0), do: []
  def create_arcs(n, idx) do
    for i <- 1..n, reduce: [] do
      acc when i==idx -> acc
      acc -> [{idx, i} | acc ]
    end
    ++ create_arcs(n, idx-1)
  end

  def create_domains(n, idx, domains \\ %{})
  def create_domains(_n, 0, domains), do: domains
  def create_domains(n, idx, domains),
    do: create_domains(n, idx-1, Map.put(domains, idx, Enum.to_list(1..n)))

  def create_arcs_to(n, c2, skip \\ nil)
  def create_arcs_to(n, c2, skip) do
    for i <- 1..n, reduce: [] do
      acc when i==c2 or i == skip -> acc
      acc -> [{i, c2} | acc ]
    end
  end

  def solve(arcs, domains, n)
  def solve([], domains, _n), do: {:ok, domains}
  def solve([arc={c1, c2}|arcs], domains, n) do
    { constrained, domains } = arc_reduce(arc, domains)
    if not constrained do
      if domains[c1] == [] do
        {:failed, domains}
      else
        solve(arcs ++ create_arcs_to(n, c1, c2), domains, n)
      end
    else
      solve(arcs, domains, n)
    end
  end

  def satisfy(c1, r1, c2, d2)
  def satisfy(_c1, _r1, _c2, []), do: false
  def satisfy(c1, r1, c2, [r2|d2]) do
    # horizontal and diagonal constraint
    constraint = r1 != r2 and abs(r2-r1) != abs(c2-c1)
    constraint or satisfy(c1, r1, c2, d2)
  end

  # returns an updated d1 that contains only values that can be satisfied with the other domain in
  # the arc, and whether or not the original d1 was fully constrained
  def satisfy_all(arc, d1, d2)
  def satisfy_all(_arc, [], _d2), do: { true, [] }
  def satisfy_all(arc={c1, c2}, [r1|d1], d2) do
    constraint = satisfy(c1, r1, c2, d2)
    {constrained, d1} = satisfy_all(arc, d1, d2)
    {
      constraint and constrained,
      (if constraint, do: [r1|d1], else: d1)
    }
  end

  def arc_reduce(arc, domains)
  def arc_reduce(arc={c1, c2}, domains) do
    {constrained, d1} = satisfy_all(arc, domains[c1], domains[c2])
    domains = %{ domains | c1 => d1 }
    { constrained, domains}
  end
end

IO.inspect Solution.solve_n_queens(4)
IO.inspect Solution.solve_n_queens(5)
IO.inspect Solution.solve_n_queens(6)
IO.inspect Solution.solve_n_queens(7)
IO.inspect Solution.solve_n_queens(9)
