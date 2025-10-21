const API_BASE_URL = '/api';

export const customerAPI = {
  // Get all customers
  getAll: async () => {
    const response = await fetch(`${API_BASE_URL}/customers`);
    if (!response.ok) throw new Error('Failed to fetch customers');
    return response.json();
  },

  // Get customer by ID
  getById: async (id) => {
    const response = await fetch(`${API_BASE_URL}/customers/${id}`);
    if (!response.ok) throw new Error('Failed to fetch customer');
    return response.json();
  },

  // Create customer
  create: async (customer) => {
    const response = await fetch(`${API_BASE_URL}/customers`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(customer)
    });
    if (!response.ok) throw new Error('Failed to create customer');
    return response.json();
  },

  // Update customer
  update: async (id, customer) => {
    const response = await fetch(`${API_BASE_URL}/customers/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(customer)
    });
    if (!response.ok) throw new Error('Failed to update customer');
    return response.json();
  },

  // Delete customer
  delete: async (id) => {
    const response = await fetch(`${API_BASE_URL}/customers/${id}`, {
      method: 'DELETE'
    });
    if (!response.ok) throw new Error('Failed to delete customer');
    return response.json();
  }
};
