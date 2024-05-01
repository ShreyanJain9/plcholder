defmodule Plcholder.Jobs do
  def get_all() do
    DynamicSupervisor.which_children(Plcholder.Jobs.Supervisor)
  end
end
