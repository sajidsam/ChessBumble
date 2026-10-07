const mongoose = require('mongoose');

const personInfoSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  contact: {
    type: String,
    required: true
  },
  ministry: {
    type: String,
    required: true
  }
}, { timestamps: true });

module.exports = mongoose.model('PersonInfo', personInfoSchema);
