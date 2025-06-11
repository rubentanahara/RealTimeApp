import React from 'react';
import { Box, Typography, Stack, Divider } from '@mui/material';
import { Trip } from '../types/trip';

interface TripDetailsProps {
    trip: Trip | null;
}

const TripDetails: React.FC<TripDetailsProps> = ({ trip }) => {
    if (!trip) {
        return (
            <Box sx={{ textAlign: 'center', py: 3 }}>
                <Typography variant="h6" color="text.secondary">
                    No trip details available
                </Typography>
            </Box>
        );
    }

    return (
        <Box>
            <Typography variant="h6" gutterBottom>
                Trip Details
            </Typography>
            
            <Stack spacing={2}>
                <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
                    <Box flex={1}>
                        <Typography variant="subtitle2" color="text.secondary">
                            Driver ID
                        </Typography>
                        <Typography variant="body1">
                            {trip.driverId}
                        </Typography>
                    </Box>
                    
                    <Box flex={1}>
                        <Typography variant="subtitle2" color="text.secondary">
                            Vehicle ID
                        </Typography>
                        <Typography variant="body1">
                            {trip.vehicleId}
                        </Typography>
                    </Box>
                </Stack>
                
                <Divider />
                
                <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
                    <Box flex={1}>
                        <Typography variant="subtitle2" color="text.secondary">
                            Version
                        </Typography>
                        <Typography variant="body1">
                            {trip.version}
                        </Typography>
                    </Box>
                    
                    <Box flex={1}>
                        <Typography variant="subtitle2" color="text.secondary">
                            Last Modified
                        </Typography>
                        <Typography variant="body1">
                            {new Date(trip.lastModified).toLocaleString()}
                        </Typography>
                    </Box>
                </Stack>
            </Stack>
        </Box>
    );
};

export default TripDetails; 