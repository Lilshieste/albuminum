const IMAGES = [
  { id: 1, path: 'http://localhost:3001/images/img1.png', uploadedAt: '2024-06-15' },
  { id: 2, path: 'http://localhost:3001/images/img2.png', uploadedAt: '2024-06-16' },
  { id: 3, path: 'http://localhost:3001/images/image3.png', uploadedAt: '2024-06-17' },
  { id: 4, path: 'http://localhost:3001/images/img4.png', uploadedAt: '2024-06-18' },
  { id: 5, path: 'http://localhost:3001/images/image_5.png', uploadedAt: '2024-12-25' },
  { id: 6, path: 'http://localhost:3001/images/image6.png', uploadedAt: '2024-12-25' },
  { id: 7, path: 'http://localhost:3001/images/img7.png', uploadedAt: '2024-12-25' },
  { id: 8, path: 'http://localhost:3001/images/image8.png', uploadedAt: '2024-09-10' },
];

const getAlbums = () => {
   return ([
    {
      id: 1,
      title: 'Summer Vacation 2024',
      description: 'Beach and mountain adventures',
      coverImage: IMAGES[0],
      images: [
        IMAGES[0],
        IMAGES[2],
        IMAGES[4],
      ],
      createdAt: '2024-06-15'
    },
    {
      id: 2,
      title: 'Family Gathering',
      description: 'Holiday celebrations',
      coverImage: IMAGES[6],
      images: [
        IMAGES[1],
        IMAGES[3],
        IMAGES[6],
        IMAGES[7],
      ],
      createdAt: '2024-12-25'
    },
    {
      id: 3,
      title: 'City Explorations',
      description: 'Urban photography',
      coverImage: IMAGES[5],
      images: [
        IMAGES[5],
      ],
      createdAt: '2024-09-10'
    }
  ]);
}

const getImages = () => IMAGES;

module.exports = {
  getAlbums,
  getImages
 };