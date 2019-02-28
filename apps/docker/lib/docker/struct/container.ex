defmodule Docker.Struct.Container do
  @moduledoc """
  Default container description
  """
  @type t :: %__MODULE__{
          id: binary,
          image: binary,
          name: binary,
          ports: [binary | {binary, binary}],
          env: map()
        }

  defstruct id: "",
            image: "",
            name: "",
            ports: [],
            env: %{}

  def test() do
    %__MODULE__{
      image: "postgres",
      name: "pg_test",
      ports: [5432],
      env: %{"POSTGRES_PASSWORD" => "portgres"}
    }
  end
end
