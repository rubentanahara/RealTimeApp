import React, { useState } from 'react';
import { useDrivers } from '../hooks/useDrivers';
import { useVehicles } from '../hooks/useVehicles';
import { CreateTripRequest } from '../types/trip';

interface TripFormProps {
    onSubmit: (trip: CreateTripRequest) => void;
    loading?: boolean;
}

export const TripForm: React.FC<TripFormProps> = ({ onSubmit, loading = false }) => {
    const { drivers, loading: driversLoading, error: driversError } = useDrivers();
    const { vehicles, loading: vehiclesLoading, error: vehiclesError } = useVehicles();
    
    const [formData, setFormData] = useState<CreateTripRequest>({
        tripNumber: '',
        driverId: '',
        vehicleId: ''
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (formData.tripNumber && formData.driverId && formData.vehicleId) {
            onSubmit(formData);
        }
    };

    const handleChange = (field: keyof CreateTripRequest, value: string) => {
        setFormData(prev => ({ ...prev, [field]: value }));
    };

    const isFormLoading = driversLoading || vehiclesLoading || loading;
    const hasErrors = driversError || vehiclesError;

    return (
        <form onSubmit={handleSubmit} className="space-y-4 p-6 bg-white rounded-lg shadow">
            <h2 className="text-2xl font-bold mb-4">Create New Trip</h2>
            
            {hasErrors && (
                <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
                    {driversError && <p>Drivers: {driversError}</p>}
                    {vehiclesError && <p>Vehicles: {vehiclesError}</p>}
                </div>
            )}

            <div>
                <label htmlFor="tripNumber" className="block text-sm font-medium text-gray-700 mb-2">
                    Trip Number
                </label>
                <input
                    id="tripNumber"
                    type="text"
                    value={formData.tripNumber}
                    onChange={(e) => handleChange('tripNumber', e.target.value)}
                    className="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="Enter trip number"
                    required
                />
            </div>

            <div>
                <label htmlFor="driver" className="block text-sm font-medium text-gray-700 mb-2">
                    Select Driver
                </label>
                <select
                    id="driver"
                    value={formData.driverId}
                    onChange={(e) => handleChange('driverId', e.target.value)}
                    className="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    required
                    disabled={driversLoading}
                >
                    <option value="">
                        {driversLoading ? 'Loading drivers...' : 'Select a driver'}
                    </option>
                    {drivers.map((driver) => (
                        <option key={driver.id} value={driver.id}>
                            {driver.name} - {driver.licenseNumber}
                        </option>
                    ))}
                </select>
            </div>

            <div>
                <label htmlFor="vehicle" className="block text-sm font-medium text-gray-700 mb-2">
                    Select Vehicle
                </label>
                <select
                    id="vehicle"
                    value={formData.vehicleId}
                    onChange={(e) => handleChange('vehicleId', e.target.value)}
                    className="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    required
                    disabled={vehiclesLoading}
                >
                    <option value="">
                        {vehiclesLoading ? 'Loading vehicles...' : 'Select a vehicle'}
                    </option>
                    {vehicles.map((vehicle) => (
                        <option key={vehicle.id} value={vehicle.id}>
                            {vehicle.licensePlate} - {vehicle.model}
                        </option>
                    ))}
                </select>
            </div>

            <button
                type="submit"
                disabled={isFormLoading || !formData.tripNumber || !formData.driverId || !formData.vehicleId}
                className="w-full bg-blue-600 text-white p-3 rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors"
            >
                {loading ? 'Creating Trip...' : 'Create Trip'}
            </button>
        </form>
    );
}; 