import React from 'react';
import { Box, Typography, Chip, CircularProgress } from '@mui/material';
import { Trip } from '../types/trip';

interface TripStatusProps {
    trip: Trip | null;
    isMonitoring: boolean;
}

const TripStatus: React.FC<TripStatusProps> = ({ trip, isMonitoring }) => {
    const getStatusColor = (status: string) => {
        switch (status?.toLowerCase()) {
            case 'in_progress':
                return 'primary';
            case 'completed':
                return 'success';
            case 'delayed':
                return 'warning';
            case 'cancelled':
                return 'error';
            default:
                return 'default';
        }
    };

    if (!isMonitoring) {
        return (
            <Box sx={{ textAlign: 'center', py: 3 }}>
                <Typography variant="h6" color="text.secondary">
                    Not monitoring any trip
                </Typography>
            </Box>
        );
    }

    if (!trip) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 3 }}>
                <CircularProgress />
            </Box>
        );
    }

    return (
        <Box>
            <Typography variant="h6" gutterBottom>
                Trip Status
            </Typography>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Chip 
                    label={trip.status} 
                    color={getStatusColor(trip.status)}
                    size="medium"
                />
                <Typography variant="body1">
                    Trip Number: {trip.tripNumber}
                </Typography>
            </Box>
            <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                Last Updated: {new Date(trip.lastModified).toLocaleString()}
            </Typography>
        </Box>
    );
};

export default TripStatus; 