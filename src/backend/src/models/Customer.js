const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
    minlength: 2,
    maxlength: 100
  },
  address: {
    type: String,
    required: true,
    trim: true,
    minlength: 5,
    maxlength: 200
  },
  country: {
    type: String,
    required: true,
    trim: true,
    minlength: 2,
    maxlength: 50
  },
  gender: {
    type: String,
    required: true,
    enum: ['Male', 'Female', 'Other']
  },
  age: {
    type: Number,
    required: true,
    min: 0,
    max: 150
  }
}, {
  timestamps: true
});

// Indexes
customerSchema.index({ name: 1 });
customerSchema.index({ country: 1 });
customerSchema.index({ age: 1 });

module.exports = mongoose.model('Customer', customerSchema);