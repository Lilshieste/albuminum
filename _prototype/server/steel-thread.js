//const baseUrl = ;

const IMAGES = [
  { id: 1, path: '/images/img1.png', uploadedAt: '2024-06-15' },
  { id: 2, path: '/images/img2.png', uploadedAt: '2024-06-16' },
  { id: 3, path: '/images/image3.png', uploadedAt: '2024-06-17' },
  { id: 4, path: '/images/img4.png', uploadedAt: '2024-06-18' },
  { id: 5, path: '/images/image_5.png', uploadedAt: '2024-12-25' },
  { id: 6, path: '/images/image6.png', uploadedAt: '2024-12-25' },
  { id: 7, path: '/images/img7.png', uploadedAt: '2024-12-25' },
  { id: 8, path: '/images/image8.png', uploadedAt: '2024-09-10' },
];

const getAlbums = () => {
  const images = getImages();
   return ([
    {
      id: 1,
      title: 'Summer Vacation 2024',
      description: 'Beach and mountain adventures',
      coverImage: images[0],
      images: [
        images[0],
        images[2],
        images[4],
      ],
      createdAt: '2024-06-15'
    },
    {
      id: 2,
      title: 'Family Gathering',
      description: 'Holiday celebrations',
      coverImage: images[6],
      images: [
        images[1],
        images[3],
        images[6],
        images[7],
      ],
      createdAt: '2024-12-25'
    },
    {
      id: 3,
      title: 'City Explorations',
      description: 'Urban photography',
      coverImage: images[5],
      images: [
        images[5],
      ],
      createdAt: '2024-09-10'
    }
  ]);
}

const getImages = () => {
  return IMAGES.map(img => ({
    ...img,
    path: `${process.env.API_BASE_URL}${img.path}`
  }));
};

module.exports = {
  getAlbums,
  getImages
 };