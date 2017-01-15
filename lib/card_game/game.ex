defmodule CardGame.Game do
  use GenServer
  @cards [{"2", "Spades"}, {"3", "Spades"}, {"4", "Spades"}, {"5", "Spades"},
    {"6", "Spades"}, {"7", "Spades"}, {"8", "Spades"}, {"9", "Spades"},
    {"10", "Spades"}, {"Jack", "Spades"}, {"Queen", "Spades"},
    {"King", "Spades"}, {"Ace", "Spades"}, {"2", "Diamonds"}, {"3", "Diamonds"},
    {"4", "Diamonds"}, {"5", "Diamonds"}, {"6", "Diamonds"}, {"7", "Diamonds"},
    {"8", "Diamonds"}, {"9", "Diamonds"}, {"10", "Diamonds"},
    {"Jack", "Diamonds"}, {"Queen", "Diamonds"}, {"King", "Diamonds"},
    {"Ace", "Diamonds"}, {"2", "Hearts"}, {"3", "Hearts"}, {"4", "Hearts"},
    {"5", "Hearts"}, {"6", "Hearts"}, {"7", "Hearts"}, {"8", "Hearts"},
    {"9", "Hearts"}, {"10", "Hearts"}, {"Jack", "Hearts"}, {"Queen", "Hearts"},
    {"King", "Hearts"}, {"Ace", "Hearts"}, {"2", "Clubs"}, {"3", "Clubs"},
    {"4", "Clubs"}, {"5", "Clubs"}, {"6", "Clubs"}, {"7", "Clubs"},
    {"8", "Clubs"}, {"9", "Clubs"}, {"10", "Clubs"}, {"Jack", "Clubs"},
    {"Queen", "Clubs"}, {"King", "Clubs"}, {"Ace", "Clubs"}]

  defstruct users: [], name: "", is_active: false, current_turn: "", user_cards: [], current_trick: [], user_tricks: []
  def start_link(name, agent) do
    game = Agent.get(agent, fn x -> x end)
    GenServer.start_link(__MODULE__, {game, agent}, name: via_tuple(name))
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

  def handle_cast({:leave, user}, {game, agent}) do
    users = game.users
    if (Enum.member?(users, user)) do
      new_game = %{game | users: List.delete(users, user)}
      {:noreply, {new_game, agent}}
    else
      {:noreply, {game, agent}}
    end
  end

  def handle_call(:deal, _from, {game = %CardGame.Game{users: users, is_active: true}, agent}) do
    if length(users) == 4 do
      new_game = %{deal_cards(game) | current_turn: hd(users)}
      {:reply, {:current_turn, new_game.current_turn}, {new_game, agent}}
    else
      {:reply, {:error, "Players not available"}, {game, agent}}
    end
  end

  def handle_call({:play_turn, user, card}, _from, {game = %CardGame.Game{current_turn: user}, agent}) do
    len = length(game.users)
    next_user = Enum.at(game.users, rem(Enum.find_index(game.users, fn x -> x == user end) + 1, len))
    {:reply, {user, card}, {%{game | current_turn: next_user}, agent}}
  end

  def handle_call({:join, user}, _from, {game, agent}) do
    users = game.users
    len = length(users)
    if len < 4 do
      new_game = %{game | users: [ user | users], is_active: len == 3}
      {:reply, {:ok, new_game.users}, {new_game, agent}}
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

end
