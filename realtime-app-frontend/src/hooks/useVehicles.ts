import { useState, useEffect } from 'react';
import { Vehicle } from '../types/vehicle';

const API_BASE_URL = import.meta.env.VITE_API_URL + '/api';

export const useVehicles = () => {
    const [vehicles, setVehicles] = useState<Vehicle[]>([]);
    const [availableVehicles, setAvailableVehicles] = useState<Vehicle[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    const fetchVehicles = async () => {
        try {
            setLoading(true);
            const [allResponse, availableResponse] = await Promise.all([
                fetch(`${API_BASE_URL}/Vehicle`),
                fetch(`${API_BASE_URL}/Vehicle/available`)
            ]);

            if (!allResponse.ok || !availableResponse.ok) {
                throw new Error('Failed to fetch vehicles');
            }

            const allVehicles = await allResponse.json();
            const availableVehicles = await availableResponse.json();

            setVehicles(allVehicles);
            setAvailableVehicles(availableVehicles);
            setError(null);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'An error occurred');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchVehicles();
    }, []);

    return {
        vehicles,
        availableVehicles,
        loading,
        error,
        refetch: fetchVehicles
    };
}; 