defmodule Sonosex.Speaker do
  defstruct [:ip, :name, :uuid, :model, :group_id, :coordinator_uuid, :household_id]

  def coordinator?(%__MODULE__{uuid: uuid, coordinator_uuid: coordinator_uuid}) do
    uuid == coordinator_uuid
  end
end
