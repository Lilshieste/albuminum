const express = require('express');
const cors = require('cors');
const path = require('path');
const albumsRouter = require('./routes/albums');

require('dotenv').config();

const app = express();
const port = parseInt(process.env.PORT, 10);

if (isNaN(port)) {
  console.error("CRITICAL ERROR: PORT environment variable is not set or invalid.");
  process.exit(1);
}

app.use(cors());
app.use(express.json());

app.use('/images', express.static(path.join(__dirname, 'public/images')));

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

app.use('/api/albums', albumsRouter);

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});