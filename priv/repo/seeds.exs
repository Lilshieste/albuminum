# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias Albuminum.Gallery

# Predefined images using picsum.photos
# Each gets unique seed for consistent images
predefined_images = [
  %{filename: "Mountain Sunrise", path: "https://picsum.photos/seed/mountain/400/300"},
  %{filename: "Ocean Waves", path: "https://picsum.photos/seed/ocean/400/300"},
  %{filename: "Forest Path", path: "https://picsum.photos/seed/forest/400/300"},
  %{filename: "City Lights", path: "https://picsum.photos/seed/city/400/300"},
  %{filename: "Desert Dunes", path: "https://picsum.photos/seed/desert/400/300"},
  %{filename: "Autumn Leaves", path: "https://picsum.photos/seed/autumn/400/300"},
  %{filename: "Snow Peak", path: "https://picsum.photos/seed/snow/400/300"},
  %{filename: "Beach Sunset", path: "https://picsum.photos/seed/beach/400/300"},
  %{filename: "River Valley", path: "https://picsum.photos/seed/river/400/300"},
  %{filename: "Wildflowers", path: "https://picsum.photos/seed/flowers/400/300"},
  %{filename: "Starry Night", path: "https://picsum.photos/seed/stars/400/300"},
  %{filename: "Rainy Day", path: "https://picsum.photos/seed/rain/400/300"}
]

IO.puts("Seeding #{length(predefined_images)} images...")

for attrs <- predefined_images do
  case Gallery.create_image(attrs) do
    {:ok, image} -> IO.puts("  Created: #{image.filename}")
    {:error, changeset} -> IO.puts("  Error: #{inspect(changeset.errors)}")
  end
end

IO.puts("Done!")
