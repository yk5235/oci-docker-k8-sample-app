import React, { useState, useEffect } from 'react';

const CustomerForm = ({ addCustomer, editingCustomer, updateCustomer }) => {
  const [customer, setCustomer] = useState({
    name: '',
    address: '',
    country: '',
    gender: '',
    age: ''
  });

  useEffect(() => {
    if (editingCustomer) {
      setCustomer(editingCustomer);
    }
  }, [editingCustomer]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setCustomer({ ...customer, [name]: value });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (editingCustomer) {
      updateCustomer(customer);
    } else {
      addCustomer(customer);
    }
    setCustomer({
      name: '',
      address: '',
      country: '',
      gender: '',
      age: ''
    });
  };

  return (
    <form onSubmit={handleSubmit} className="customer-form">
      <label>Name:</label>
      <input type="text" name="name" value={customer.name} onChange={handleChange} required />
      
      <label>Address:</label>
      <input type="text" name="address" value={customer.address} onChange={handleChange} required />
      
      <label>Country:</label>
      <input type="text" name="country" value={customer.country} onChange={handleChange} required />
      
      <label>Gender:</label>
      <select name="gender" value={customer.gender} onChange={handleChange} required>
        <option value="">Select Gender</option>
        <option value="Male">Male</option>
        <option value="Female">Female</option>
        <option value="Other">Other</option>
      </select>
      
      <label>Age:</label>
      <input type="number" name="age" value={customer.age} onChange={handleChange} required />
      
      <button type="submit">{editingCustomer ? 'Update' : 'Add'} Customer</button>
    </form>
  );
};

export default CustomerForm;
