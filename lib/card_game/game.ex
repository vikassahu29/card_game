defmodule CardGame.Game do
  use GenServer
  @cards [{"2", "Spades", 2}, {"3", "Spades", 3}, {"4", "Spades", 4}, {"5", "Spades", 5},
    {"6", "Spades", 6}, {"7", "Spades", 7}, {"8", "Spades", 8}, {"9", "Spades", 9},
    {"10", "Spades", 10}, {"Jack", "Spades", 11}, {"Queen", "Spades", 12},
    {"King", "Spades", 13}, {"Ace", "Spades", 1}, {"2", "Diamonds", 2}, {"3", "Diamonds", 3},
    {"4", "Diamonds", 4}, {"5", "Diamonds", 5}, {"6", "Diamonds", 6}, {"7", "Diamonds", 7},
    {"8", "Diamonds", 8}, {"9", "Diamonds", 9}, {"10", "Diamonds", 10},
    {"Jack", "Diamonds", 11}, {"Queen", "Diamonds", 12}, {"King", "Diamonds", 13},
    {"Ace", "Diamonds", 1}, {"2", "Hearts", 2}, {"3", "Hearts", 3}, {"4", "Hearts", 4},
    {"5", "Hearts", 5}, {"6", "Hearts", 6}, {"7", "Hearts", 7}, {"8", "Hearts", 8},
    {"9", "Hearts", 9}, {"10", "Hearts", 10}, {"Jack", "Hearts", 11}, {"Queen", "Hearts", 12},
    {"King", "Hearts", 13}, {"Ace", "Hearts", 1}, {"2", "Clubs", 2}, {"3", "Clubs", 3},
    {"4", "Clubs", 4}, {"5", "Clubs", 5}, {"6", "Clubs", 6}, {"7", "Clubs", 7},
    {"8", "Clubs", 8}, {"9", "Clubs", 9}, {"10", "Clubs", 10}, {"Jack", "Clubs", 11},
    {"Queen", "Clubs", 12}, {"King", "Clubs", 13}, {"Ace", "Clubs", 1}]

  @suits ["Diamonds", "Spades", "Clubs", "Hearts"]
  @state_not_started 1
  @state_select_trump 2
  @state_playing 3

  defstruct users: [], name: "", state: @state_not_started, current_turn: "", user_cards: [], current_trick: [], last_trick: [], last_trick_winner: "", user_tricks: %{}, trump: ""
  def start_link(name, agent) do
    game = Agent.get(agent, fn x -> x end)
    GenServer.start_link(__MODULE__, {%{game | name: name}, agent}, name: via_tuple(name))
  end

  defp via_tuple(room_name) do
    {:via, :gproc, {:n, :l, {:card_game, room_name}}}
  end

  def deal(name) do
    GenServer.call(via_tuple(name), :deal)
  end

  def play_turn(name, user, card) do
    GenServer.call(via_tuple(name), {:play_turn, user, card})
  end

  def leave_game(name, user) do
    GenServer.cast(via_tuple(name), {:leave, user})
  end

  def join_game(name, user) do
    GenServer.call(via_tuple(name), {:join, user})
  end

  def get_cards(name, user) do
    GenServer.call(via_tuple(name), {:get_cards, user})
  end

  def select_trump(name, user, card) do
    GenServer.call(via_tuple(name), {:select_trump, user, card})
  end

  def setup(name) do
    GenServer.call(via_tuple(name), {:setup})
  end

  def handle_call({:setup}, _from, {game, agent}) do
    new_game = %{game | users: ["4", "3", "2", "1"], user_tricks: %{"1" => [], "2" => [], "3" => [], "4" => []}}
    {:reply, {:ok}, {new_game = %{deal_cards(new_game) | current_turn: hd(new_game.users), state: @state_select_trump}, agent}}
  end

  def handle_cast({:leave, user}, {game, agent}) do
    users = game.users
    if (Enum.member?(users, user)) do
      new_game = %{game | users: List.delete(users, user)}
      {:noreply, {new_game, agent}}
    else
      {:noreply, {game, agent}}
    end
  end

  def handle_call({:select_trump, user, suit}, _from, {game = %CardGame.Game{state: @state_select_trump, current_turn: user}, agent}) do
    if (Enum.member?(@suits, suit)) do
      {:reply, {:ok}, {%{game | state: @state_playing, trump: suit}, agent}}
    else
      {:reply, {:error, "Invalid Suit", {game, agent}}}
    end
  end

  def handle_call(:deal, _from, {game = %CardGame.Game{users: users, state: @state_not_started}, agent}) do
    if length(users) == 4 do
      new_game = %{deal_cards(game) | current_turn: hd(users), state: @state_select_trump}
      {:reply, {:current_turn, new_game.current_turn}, {new_game, agent}}
    else
      {:reply, {:error, "Players not available"}, {game, agent}}
    end
  end
#Todo

  def handle_call({:play_turn, user, card}, _from, {game = %CardGame.Game{current_turn: user, current_trick: current_trick}, agent}) do
    user_cards = Enum.at(game.user_cards, Enum.find_index(game.users, fn x -> x == user end))
    # IO.puts(is_card_valid(card, current_trick, user_cards))
    if (is_card_valid(card, current_trick, user_cards)) do
      IO.puts("Valid")
      {:reply, {:ok}, {game, agent}}
      # new_trick = [%{card: card, user: user} | current_trick]
      # len = length(new_trick)
      # if (len === 4) do
      #   new_game = calculate_result(%{game | current_trick: new_trick})
      #   {:reply, {user, card}, {new_game, agent}}
      # else
      #   next_user = Enum.at(game.users, rem(Enum.find_index(game.users, fn x -> x == user end) + 1, len))
      #   {:reply, {user, card}, {%{game | current_turn: next_user }, agent}}
      # end
    else
      {:reply, {:error, "Invalid Card"}, {game, agent}}
    end
    # {:reply, {:ok}, {game, agent}}
  end

  def handle_call({:join, user}, _from, {game, agent}) do
    users = game.users
    len = length(users)
    if len < 4 do
      if len == 3 do
        new_game = %{game | users: [ user | users], state: @state_not_started, user_tricks: Map.put_new(game.user_tricks, user, [])}
        {:reply, {:ok, new_game.users}, {new_game, agent}}
      else
        new_game = %{game | users: [ user | users], user_tricks: Map.put_new(game.user_tricks, user, [])}
        {:reply, {:ok, new_game.users}, {new_game, agent}}
      end
    else
      {:reply, {:error, "Server Full"}, {game, agent}}
    end
  end

  def handle_call({:get_cards, user}, _from, {game, agent}) do
    user_cards = Enum.find(game.user_cards, nil, fn(x) -> elem(x, 0) == user end)
    if user_cards == nil do
      {:reply, {:error, "User not found"}, {game, agent}}
    else
      {:reply, {:ok, user_cards}, {game, agent}}
    end
  end

  def terminate(_reason, {game, agent}) do
    Agent.update(agent, fn _ -> game end)
  end

  defp deal_cards(game) do
    [head | tail] = game.users
    deal_user(head, tail, game, Enum.shuffle(@cards))
  end

  defp deal_user(user, [], game, cards) do
    %{game | user_cards: [ {user, Enum.take(cards, 13)} | game.user_cards]}
  end

  defp deal_user(user, [x | xs], game, cards) do
    new_game = %{game | user_cards: [ {user, Enum.take(cards, 13)} | game.user_cards]}
    rem_cards = Enum.drop(cards, 13)
    deal_user(x, xs, new_game, rem_cards)
  end

  def is_card_valid(card, trick, user_cards) do
    true
    # {_, suit, _} = hd(Enum.reverse(trick))
    # {_, card_suit, _} = card
    # if (suit === card_suit) do
    #   true
    # else
    #   Enum.all?(user_cards, fn {_, s, _} -> s != suit end)
    # end
  end

  def calculate_result(game = %CardGame.Game{state: @state_playing}) do
    current_trick_winner = find_trick_winner(game.current_trick, game.trump);
    if game.last_trick_winner == current_trick_winner do
      new_user_tricks = game.user_tricks[current_trick_winner] ++ [game.current_trick] ++ game.last_trick
      %{game | current_trick: [], last_trick: [], last_trick_winner: nil, current_turn: current_trick_winner, user_tricks: new_user_tricks}
    else
      %{game | current_trick: [], last_trick_winner: current_trick_winner, last_trick: [game.current_trick | game.last_trick], current_turn: current_trick_winner}
    end
  end

  def find_trick_winner(trick, trump) do
    p1 = hd(trick)
    trick_suit = elem(p1.card, 1)
    if trick_suit == trump do
      Enum.filter(trick, fn x -> elem(x.card, 1) == trump end) |> Enum.max_by(fn x -> get_card_value(x.card) end)
    else
      t_result = Enum.filter(trick, fn x -> elem(x.card, 1) == trump end)
      if Enum.empty?(t_result) do
        Enum.filter(trick, fn x -> elem(x.card, 1) == trick_suit end) |> Enum.max_by(fn x -> get_card_value(x.card) end)
      else
        Enum.max_by(t_result, fn x -> get_card_value(x.card) end)
      end
    end
  end

  defp get_card_value({_, _, 1}) do
    14
  end

  defp get_card_value({_, _, v}) do
    v
  end

end
