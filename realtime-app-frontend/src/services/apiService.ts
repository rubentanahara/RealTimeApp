import axios from 'axios';
import { Trip, CreateTripRequest, UpdateTripStatusRequest } from '../types/trip';

const API_BASE_URL = import.meta.env.VITE_API_URL + '/api';
console.log('API URL:', import.meta.env.VITE_API_URL);

export const apiService = {
    async getAllTrips(): Promise<Trip[]> {
        const response = await axios.get<Trip[]>(`${API_BASE_URL}/trip`);
        return response.data;
    },

    async getTripById(id: string): Promise<Trip> {
        const response = await axios.get<Trip>(`${API_BASE_URL}/trip/${id}`);
        return response.data;
    },

    async getTripByNumber(tripNumber: string): Promise<Trip> {
        const response = await axios.get<Trip>(`${API_BASE_URL}/trip/number/${tripNumber}`);
        return response.data;
    },

    async createTrip(request: CreateTripRequest): Promise<Trip> {
        const response = await axios.post<Trip>(`${API_BASE_URL}/trip`, request);
        return response.data;
    },

    async updateTripStatus(id: string, request: UpdateTripStatusRequest): Promise<Trip> {
        const response = await axios.put<Trip>(`${API_BASE_URL}/trip/${id}/status`, request);
        return response.data;
    },

    async completeTrip(id: string): Promise<Trip> {
        const response = await axios.put<Trip>(`${API_BASE_URL}/trip/${id}/complete`);
        return response.data;
    }
}; 