defmodule Westar do
  def extract do
    file = "westar_fusion_table_export.kml"
    data = File.read!(file)
      |> Floki.find("multigeometry")
      |> Floki.raw_html

    File.write!("westar_extracted.kml", data)
  end

  def process do
    file = "westar_extracted.kml"
    File.read!(file)
    |> Floki.find("polygon")
    |> Stream.map(fn x ->
      out_search = x
        |> Floki.find("outerboundaryis")

      out_points = case out_search do
        [{"outerboundaryis", [], [{"linearring", [], [{"coordinates", [], coords}]}]}] ->
          coords
          |> parse_kml_coords

        _ ->
          []
      end

      in_search = x
        |> Floki.find("innerboundaryis")

      in_points = case in_search do
        [{"innerboundaryis", [], [{"linearring", [], [{"coordinates", [], coords}]}]}] ->
          coords
          |> parse_kml_coords

        _ ->
          []
      end
      {out_points, in_points}
    end)
    |> Enum.filter(fn {out_points, in_points} ->
      length(out_points) > 0 or length(in_points) > 0
    end)
  end

  def parse_kml_coords([coords]), do: parse_kml_coords(coords)
  def parse_kml_coords(coords) when is_bitstring(coords) do
    coords
    |> String.split(" ")
    |> Enum.map(fn x ->
      [lat | [lng | _]] = x
        |> String.split(",")
      {lat, lng}
    end)
  end
  def parse_kml_coords(_), do: []

  def lat_long_in_polygon?(lat, lng, polygons) do
    start_point = length(polygons) - 1
    {inside, _} = polygons
      |> Enum.with_index
      |> Enum.reduce({false, start_point}, fn {{xi, yi}, idx}, {inside, itr_point} ->
        {xj, yj} = Enum.at(polygons, itr_point)
        intersect = ((yi > lng) != (yj > lng)) && (lat < (xj - xi) * (lng - yi) / (yj - yi) + xi)
        if intersect, do: inside = not inside
        {inside, idx + 1}
      end)
    inside
  end

  def lat_long_in_kml_polygon?(lat, lng, {out_points, in_points}) when length(out_points) > 0 and length(in_points) >= 0 do
    lat_long_in_polygon?(lat, lng, out_points) and (not lat_long_in_polygon?(lat, lng, in_points))
  end
  # def lat_long_in_kml_polygon?(lat, lng, {out_points, in_points}) when length(out_points) > 0 and length(in_points) === 0 do
  #   lat_long_in_polygon?(lat, lng, out_points)
  # end
  def lat_long_in_kml_polygon?(lat, lng, {out_points, in_points}) do
    false
  end
end

# Westar.extract

Westar.process
|> Enum.any?(fn x ->
  Westar.lat_long_in_kml_polygon?(-96.842775, 37.262043, x)
end)
|> IO.inspect
