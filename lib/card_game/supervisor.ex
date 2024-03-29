defmodule CardGame.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: :card_game_supervisor)
  end

  def start_room(name) do
    {:ok, agent} = Agent.start_link fn -> %CardGame.Game{} end
    Supervisor.start_child(:card_game_supervisor, [name, agent])
  end

  def init(_) do
    children = [
      worker(CardGame.Game, [])
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end
