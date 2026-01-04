const getAlbums = () => {
   return ([
    {
      id: 1,
      title: 'Summer Vacation 2024',
      description: 'Beach and mountain adventures',
      coverImage: 'http://localhost:3001/images/img1.png',
      photoCount: 24,
      createdAt: '2024-06-15'
    },
    {
      id: 2,
      title: 'Family Gathering',
      description: 'Holiday celebrations',
      coverImage: 'http://localhost:3001/images/img7.png',
      photoCount: 18,
      createdAt: '2024-12-25'
    },
    {
      id: 3,
      title: 'City Explorations',
      description: 'Urban photography',
      coverImage: 'http://localhost:3001/images/image_5.png',
      photoCount: 42,
      createdAt: '2024-09-10'
    }
  ]);
}

module.exports = { getAlbums };