defmodule Vayne.Task do

  @moduledoc """
  Abstract Vayne Task Behaviour
  """

  @type stat  :: any
  @type param :: list
  @type pk    :: binary
  @type t :: %__MODULE__{
            type:  module,
            param: param,
            pk:    pk
          }

  defstruct type:  Vayne.Task.Test,
            param: ["foo"],
            pk:    "not_defined"

  @doc """
  Generate vayne task pk according to the params
  """
  @callback pk(param) :: {:ok, String.t} | {:error, String.t}

  @doc """
  Initialize task stat
  """
  @callback init(t) :: stat

  @doc """
  Run the task with stat
  """
  @callback run(stat) :: :ok | {:error, String.t}

  @doc """
  Clean task stat
  """
  @callback clean(stat) :: :ok | {:error, String.t}

  @spec make(module, param) :: t | {:error, String.t}
  def make(module, param) do
    case module.pk(param) do
      {:ok, pk} ->
        {:ok, %Vayne.Task{type: module, pk: pk, param: param}}
      error = {:error, _error} ->
        error
      error ->
        {:error, "return wrong type: #{inspect error}"}
    end
  end
end
