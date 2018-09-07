require Integer

defmodule Game do
  def init do
    # Set up initial state
    IO.puts("")
    Agent.start(fn -> 0 end, name: MovesCount)
    GameBoard.init

    # Choose opponent
    IO.puts(IO.ANSI.green <> easy_ai_img() <> IO.ANSI.reset)
    IO.puts(IO.ANSI.blue <> med_ai_img() <> IO.ANSI.reset)
    IO.puts(IO.ANSI.red <> hard_ai_img() <> IO.ANSI.reset)
    opponent_string = IO.gets("Choose your opponent (or 'none' for human vs. human) > ") |> String.replace("\n", "")
    Agent.start(fn ->
      if Regex.match?(~r/^(easy|med|hard)$/, opponent_string) do
        opponent_string
      else
        "none"
      end
    end, name: Opponent)

    # TODO you are playing...
    IO.puts(inspect opponent())
  end

  def start do
    next_move()
  end

  def markers do
    [IO.ANSI.white <> "X" <> IO.ANSI.reset, IO.ANSI.white <> "O" <> IO.ANSI.reset]
  end

  def next_move do
    current_marker = current_marker()
    IO.puts("Time for #{current_marker} to move!")
    GameBoard.print_board()
    index_string = IO.gets("Select a position number > ")
    {index_integer, _} = Integer.parse(index_string)

    if GameBoard.update_board(index_integer, current_marker) do
      Agent.update(MovesCount, &(&1 + 1))
      GameBoard.end_check()
    else
      next_move()
    end
  end

  def victory do
    Agent.update(MovesCount, &(&1 + 1))
    GameBoard.print_board()
    IO.puts("The winner is #{Game.current_marker()}!!")
  end

  def cats_game do
    IO.puts("Cats game :(")
  end

  def opponent do
    Agent.get(Opponent, &(&1))
  end

  def moves_count do
    Agent.get(MovesCount, &(&1))
  end

  def current_marker do
    Enum.at(markers(), get_turn(moves_count()))
  end

  def get_turn(moves_count) do
    if Integer.is_even(moves_count) do
      0
    else
      1
    end
  end

  # randomly place
  def easy_ai_img do
    """
    +-easy----+ randomly picks an available spot
    |         |
    |  ʕ≧ᴥ≦ʔ  |
    +---------+
    """
  end

  # if a row has 2 of the same, choose the 3rd
  def med_ai_img do
    """
    +-med-----+ can make a winning move and block a winning move
    |         |
    |  ʕ•ᴥ•ʔ  |
    +---------+
    """
  end

  # optimal never-lose strategy
  def hard_ai_img do
    """
    +-hard----+ this bear googled the 'never lose' strategy
    |         |
    |╭∩╮ʕ•ᴥ•ʔ |
    +---------+
    """
  end
end

defmodule GameBoard do
  def init do
    Agent.start(fn -> [0, 1, 2, 3, 4, 5, 6, 7, 8] end, name: BoardState)
  end

  def end_check do
    cond do
      Game.moves_count < 5 ->
        # Game can't end in fewer than 5 moves
        Game.next_move()
      is_victory() ->
        Game.victory()
      Game.moves_count == 9 ->
        Game.cats_game()
      true ->
        Game.next_move()
    end
  end

  def victory_indices do
    [
      # rows
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],

      # cols
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],

      # diag
      [0, 4, 8],
      [6, 4, 2]
    ]
  end

  def is_victory do
    Enum.any?(victory_indices(), fn(a) ->
      [one, two, three] = a
      b = board_state()
      Enum.at(b, one) == Enum.at(b, two) && Enum.at(b, two) == Enum.at(b, three)
    end)
  end

  def board_state do
    Agent.get(BoardState, &(&1))
  end

  def print_board do
    row_divider = "---+---+---"
    b = board_state()

    # TODO: there's got to be a better way to do this
    row1 = [Enum.at(b, 0), Enum.at(b, 1), Enum.at(b, 2)]
    row2 = [Enum.at(b, 3), Enum.at(b, 4), Enum.at(b, 5)]
    row3 = [Enum.at(b, 6), Enum.at(b, 7), Enum.at(b, 8)]

    board_strings = [
      "",
      " " <> Enum.join(row1, " | ") <> " ",
      row_divider,
      " " <> Enum.join(row2, " | ") <> " ",
      row_divider,
      " " <> Enum.join(row3, " | ") <> " ",
      ""
    ]

    IO.puts(Enum.join(board_strings, "\n"))
  end

  def update_board(index, marker) do
    existing_value = Enum.at(board_state(), index)
    if is_binary(existing_value) do
      IO.puts("Sorry that is an invalid move")
      false
    else
      Agent.update(BoardState, fn board_state ->
        List.replace_at(board_state, index, marker)
      end)
    end
  end
end

Game.init
Game.start
