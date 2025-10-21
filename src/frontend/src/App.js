import React, { useState, useEffect } from 'react';
import CustomerForm from './components/CustomerForm';
import CustomerList from './components/CustomerList';
import { customerAPI } from './services/api';
import './index.css';

const App = () => {
    const [customers, setCustomers] = useState([]);
    const [editingCustomer, setEditingCustomer] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    useEffect(() => {
        fetchCustomers();
    }, []);

    const fetchCustomers = async () => {
        try {
            setLoading(true);
            setError(null);
            const data = await customerAPI.getAll();
            setCustomers(data);
        } catch (error) {
            setError('Failed to fetch customers: ' + error.message);
            console.error('Error fetching customers:', error);
        } finally {
            setLoading(false);
        }
    };

    const addCustomer = async (customer) => {
        try {
            setError(null);
            const newCustomer = await customerAPI.create(customer);
            setCustomers([...customers, newCustomer]);
        } catch (error) {
            setError('Failed to add customer: ' + error.message);
            console.error('Error adding customer:', error);
        }
    };

    const updateCustomer = async (customer) => {
        try {
            setError(null);
            const updatedCustomer = await customerAPI.update(customer._id, customer);
            setCustomers(customers.map((c) =>
                c._id === updatedCustomer._id ? updatedCustomer : c
            ));
            setEditingCustomer(null);
        } catch (error) {
            setError('Failed to update customer: ' + error.message);
            console.error('Error updating customer:', error);
        }
    };

    const deleteCustomer = async (id) => {
        try {
            setError(null);
            await customerAPI.delete(id);
            setCustomers(customers.filter((customer) => customer._id !== id));
        } catch (error) {
            setError('Failed to delete customer: ' + error.message);
            console.error('Error deleting customer:', error);
        }
    };

    const editCustomer = (customer) => {
        setEditingCustomer(customer);
    };

    return (
        <div className="container">
            <h1>Customer Data Entry</h1>

            {error && (
                <div className="error-message">
                    {error}
                    <button onClick={() => setError(null)}>✕</button>
                </div>
            )}

            <CustomerForm
                addCustomer={addCustomer}
                editingCustomer={editingCustomer}
                updateCustomer={updateCustomer}
            />

            {loading ? (
                <div className="loading">Loading customers...</div>
            ) : (
                <CustomerList
                    customers={customers}
                    deleteCustomer={deleteCustomer}
                    editCustomer={editCustomer}
                />
            )}
        </div>
    );
};

export default App;