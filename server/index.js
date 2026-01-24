const express = require('express');
const cors = require('cors');
const path = require('path');
const albumsRouter = require('./routes/albums');

require('dotenv').config();

const app = express();
const PORT = 3001;

app.use(cors());
app.use(express.json());

app.use('/images', express.static(path.join(__dirname, 'public/images')));

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

app.use('/api/albums', albumsRouter);

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});