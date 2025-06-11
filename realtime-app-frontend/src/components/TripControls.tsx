import React, { useState } from 'react';
import { Box, Typography, TextField, Button, Alert } from '@mui/material';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import StopIcon from '@mui/icons-material/Stop';

interface TripControlsProps {
    onStartMonitoring: (tripNumber: string) => Promise<void>;
    onStopMonitoring: () => Promise<void>;
    isMonitoring: boolean;
}

const TripControls: React.FC<TripControlsProps> = ({
    onStartMonitoring,
    onStopMonitoring,
    isMonitoring
}) => {
    const [tripNumber, setTripNumber] = useState('');
    const [error, setError] = useState<string | null>(null);

    const handleStartMonitoring = async () => {
        if (!tripNumber.trim()) {
            setError('Please enter a trip number');
            return;
        }

        try {
            setError(null);
            await onStartMonitoring(tripNumber);
        } catch (err) {
            setError('Failed to start monitoring');
        }
    };

    return (
        <Box>
            <Typography variant="h6" gutterBottom>
                Trip Controls
            </Typography>

            {error && (
                <Alert severity="error" sx={{ mb: 2 }}>
                    {error}
                </Alert>
            )}

            <TextField
                fullWidth
                label="Trip Number"
                value={tripNumber}
                onChange={(e) => setTripNumber(e.target.value)}
                disabled={isMonitoring}
                sx={{ mb: 2 }}
            />

            {isMonitoring ? (
                <Button
                    fullWidth
                    variant="contained"
                    color="error"
                    startIcon={<StopIcon />}
                    onClick={onStopMonitoring}
                >
                    Stop Monitoring
                </Button>
            ) : (
                <Button
                    fullWidth
                    variant="contained"
                    color="primary"
                    startIcon={<PlayArrowIcon />}
                    onClick={handleStartMonitoring}
                >
                    Start Monitoring
                </Button>
            )}
        </Box>
    );
};

export default TripControls; 