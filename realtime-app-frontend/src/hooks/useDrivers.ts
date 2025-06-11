import { useState, useEffect } from 'react';
import { Driver } from '../types/driver';

const API_BASE_URL = import.meta.env.VITE_API_URL + '/api';

export const useDrivers = () => {
    const [drivers, setDrivers] = useState<Driver[]>([]);
    const [availableDrivers, setAvailableDrivers] = useState<Driver[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    const fetchDrivers = async () => {
        try {
            setLoading(true);
            const [allResponse, availableResponse] = await Promise.all([
                fetch(`${API_BASE_URL}/Driver`),
                fetch(`${API_BASE_URL}/Driver/available`)
            ]);

            if (!allResponse.ok || !availableResponse.ok) {
                throw new Error('Failed to fetch drivers');
            }

            const allDrivers = await allResponse.json();
            const availableDrivers = await availableResponse.json();

            setDrivers(allDrivers);
            setAvailableDrivers(availableDrivers);
            setError(null);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'An error occurred');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchDrivers();
    }, []);

    return {
        drivers,
        availableDrivers,
        loading,
        error,
        refetch: fetchDrivers
    };
}; 