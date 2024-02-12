defmodule BackendFightWeb.ChangesetJSON do
  @doc """
  Renders changeset errors.
  """
  def error(%{changeset: _changeset}) do
    # When encoded, the changeset returns its errors
    # as a JSON object. So we just pass it forward.
    %{errors: "Failed validation"}
  end
end
