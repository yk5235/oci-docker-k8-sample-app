import React from 'react';

const CustomerList = ({ customers, deleteCustomer, editCustomer }) => {
  return (
    <table className="customer-list">
      <thead>
        <tr>
          <th>Name</th>
          <th>Address</th>
          <th>Country</th>
          <th>Gender</th>
          <th>Age</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        {customers.map((customer) => (
          <tr key={customer._id}>
            <td>{customer.name}</td>
            <td>{customer.address}</td>
            <td>{customer.country}</td>
            <td>{customer.gender}</td>
            <td>{customer.age}</td>
            <td>
              <button onClick={() => editCustomer(customer)} className="edit-button">Edit</button>
              <button onClick={() => deleteCustomer(customer._id)} className="delete-button">Delete</button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
};

export default CustomerList;
