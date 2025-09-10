defmodule BauleBio.Compte.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  The `BauleBio.Compte.Scope` allows public interfaces to receive
  information about the caller, such as if the call is initiated from an
  end-user, and if so, which user. Additionally, such a scope can carry fields
  such as "super user" or other privileges for use as authorization, or to
  ensure specific code paths can only be access for a given scope.

  It is useful for logging as well as for scoping pubsub subscriptions and
  broadcasts when a caller subscribes to an interface or performs a particular
  action.

  Feel free to extend the fields on this struct to fit the needs of
  growing application requirements.
  """

  alias BauleBio.Compte.Utilisateur

  defstruct utilisateur: nil

  @doc """
  Creates a scope for the given utilisateur.

  Returns nil if no utilisateur is given.
  """
  def for_utilisateur(%Utilisateur{} = utilisateur) do
    %__MODULE__{utilisateur: utilisateur}
  end

  def for_utilisateur(nil), do: nil
end
