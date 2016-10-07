defmodule Westar do
  def process do
    file = "westar.kml"
    {inner_spaced, full_block} = File.read!(file)
      |> Floki.find("multigeometry")
      |> Floki.find("polygon")
      |> Enum.partition(fn x ->
        innerboundary = x |> Floki.find("innerboundaryis")
        case innerboundary do
          [{"innerboundaryis", [], lst}] ->
            true
          _ ->
            false
        end
      end)

    parsed_block = inner_spaced
      |> process_full_block
  end

  def process_full_block(block) do
    IO.inspect block
  end

  def process_partial_block(block) do
     
  end
end

Westar.process
