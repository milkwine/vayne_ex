defmodule Vayne.Center.GuardTest do
  use ExUnit.Case, async: false
  doctest Vayne.Center.Guard
  alias Vayne.Center.GuardHelper

  test "normal" do
    GuardHelper.switch_normal()

  end

end
