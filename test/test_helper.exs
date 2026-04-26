ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Albuminum.Repo, :manual)

# Define mocks
Mox.defmock(Albuminum.GooglePhotosPickerMock, for: Albuminum.GooglePhotosPicker)
