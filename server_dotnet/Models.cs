public record ImageModel(
    int Id,
    string Path,
    string UploadedAt
);

public record AlbumModel(
    int Id,
    string Title,
    string Description,
    ImageModel CoverImage,
    List<ImageModel> Images,
    string CreatedAt
);