defmodule CardGame.Game do
  use GenServer

  defstruct users: [], name: "", is_active: false, current_turn: ""
  def start_link(game = %CardGame.Game{}) do
    GenServer.start_link(__MODULE__,game, name: __MODULE__)
  end

  def deal() do
    GenServer.cast(__MODULE__, :deal)
  end

  def play_turn(user, card) do
    GenServer.call(__MODULE__, {:play_turn, user, card})
  end

  def leave_game(user) do
    GenServer.cast(__MODULE__, {:leave, user})
  end

  def join_game(user) do
    GenServer.call(__MODULE__, {:join, user})
  end

  def handle_cast(:deal, game = %CardGame.Game{users: users, is_active: false}) do
    if length(users) == 4 do
      {:noreply, deal(game, users)}
    else
      {:noreply, game}
    end
  end

  def handle_cast({:leave, user}, game) do
    users = game.users
    if (Enum.member?(users, user)) do
      new_game = %{game | users: List.delete(users, user)}
      {:noreply, new_game}
    else
      {:noreply, game}
    end
  end

  def handle_call({:play_turn, user, card}, _from, game) do
    {:reply, {user, card}, game}
  end

  def handle_call({:join, user}, _from, game) do
    users = game.users
    if length(users) < 4 do
      new_game = %{game | users: [ user | users]}
      {:reply, new_game.users, new_game}
    else
      {:reply, :error , game}
    end
  end

  defp deal(game, _users) do
    IO.puts("Asd")
    game
  end
end
