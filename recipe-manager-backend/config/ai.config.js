const { OpenAI } = require('openai');
const { ImageAnnotatorClient } = require('@google-cloud/vision');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const visionClient = new ImageAnnotatorClient();

module.exports = {
  openai,
  visionClient,
};