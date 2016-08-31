defmodule Bolt.Sips.Exception do
  @moduledoc """
  This module defines a `Bolt.Sips.Exception` structure containing two fields:

  * `code` - the error code
  * `message` - the error details
  """
  @type t :: %Bolt.Sips.Exception{}

  defexception [:code, :message]
end
