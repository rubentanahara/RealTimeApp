import React, { useEffect, useState } from 'react';
import {
    Box,
    Button,
    Card,
    CardContent,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    Stack,
    TextField,
    Typography,
    FormControl,
    InputLabel,
    Select,
    MenuItem,
    CircularProgress,
    Alert
} from '@mui/material';
import { Trip, CreateTripRequest } from '../types/trip';
import { apiService } from '../services/apiService';
import { signalRService } from '../services/signalRService';
import { useDrivers } from '../hooks/useDrivers';
import { useVehicles } from '../hooks/useVehicles';

const TripList: React.FC = () => {
    const [trips, setTrips] = useState<Trip[]>([]);
    const [openCreateDialog, setOpenCreateDialog] = useState(false);
    const [newTrip, setNewTrip] = useState<CreateTripRequest>({
        tripNumber: '',
        driverId: '',
        vehicleId: ''
    });
    const [creating, setCreating] = useState(false);

    // Use our new hooks for drivers and vehicles
    const { drivers, loading: driversLoading, error: driversError } = useDrivers();
    const { vehicles, loading: vehiclesLoading, error: vehiclesError } = useVehicles();

    useEffect(() => {
        loadTrips();
        setupSignalR();
        return () => {
            signalRService.stopConnection();
        };
    }, []);

    const loadTrips = async () => {
        try {
            const loadedTrips = await apiService.getAllTrips();
            setTrips(loadedTrips);
        } catch (error) {
            console.error('Error loading trips:', error);
        }
    };

    const setupSignalR = async () => {
        await signalRService.startConnection();
        signalRService.onTripUpdate(() => {
            loadTrips();
        });
    };

    const handleCreateTrip = async () => {
        if (!newTrip.tripNumber || !newTrip.driverId || !newTrip.vehicleId) {
            return;
        }

        try {
            setCreating(true);
            const createdTrip = await apiService.createTrip(newTrip);
            setTrips([...trips, createdTrip]);
            setOpenCreateDialog(false);
            setNewTrip({ tripNumber: '', driverId: '', vehicleId: '' });
        } catch (error) {
            console.error('Error creating trip:', error);
        } finally {
            setCreating(false);
        }
    };

    const handleUpdateStatus = async (id: string, status: string) => {
        try {
            const updatedTrip = await apiService.updateTripStatus(id, { status });
            setTrips(trips.map(trip => trip.id === id ? updatedTrip : trip));
        } catch (error) {
            console.error('Error updating trip status:', error);
        }
    };

    const handleCompleteTrip = async (id: string) => {
        try {
            const completedTrip = await apiService.completeTrip(id);
            setTrips(trips.map(trip => trip.id === id ? completedTrip : trip));
        } catch (error) {
            console.error('Error completing trip:', error);
        }
    };

    // Helper function to get driver name
    const getDriverName = (driverId: string) => {
        const driver = drivers.find(d => d.id === driverId);
        return driver ? `${driver.name} (${driver.licenseNumber})` : driverId;
    };

    // Helper function to get vehicle info
    const getVehicleInfo = (vehicleId: string) => {
        const vehicle = vehicles.find(v => v.id === vehicleId);
        return vehicle ? `${vehicle.licensePlate} - ${vehicle.model}` : vehicleId;
    };

    const isFormValid = newTrip.tripNumber && newTrip.driverId && newTrip.vehicleId;
    const isLoading = driversLoading || vehiclesLoading || creating;
    const hasErrors = driversError || vehiclesError;

    return (
        <Box sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
                <Typography variant="h4">Trips</Typography>
                <Button
                    variant="contained"
                    color="primary"
                    onClick={() => setOpenCreateDialog(true)}
                >
                    Create Trip
                </Button>
            </Box>

            <Box sx={{ 
                display: 'grid', 
                gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', 
                gap: 3 
            }}>
                {trips.map((trip) => (
                    <Card key={trip.id}>
                        <CardContent>
                            <Typography variant="h6">Trip #{trip.tripNumber}</Typography>
                            <Typography color="textSecondary">Status: {trip.status}</Typography>
                            <Typography>Driver: {getDriverName(trip.driverId)}</Typography>
                            <Typography>Vehicle: {getVehicleInfo(trip.vehicleId)}</Typography>
                            <Typography>
                                Start: {new Date(trip.startTime).toLocaleString()}
                            </Typography>
                            {trip.endTime && (
                                <Typography>
                                    End: {new Date(trip.endTime).toLocaleString()}
                                </Typography>
                            )}
                            <Box sx={{ mt: 2 }}>
                                {trip.status !== 'Completed' && (
                                    <Stack direction="row" spacing={1}>
                                        <Button
                                            variant="contained"
                                            color="primary"
                                            onClick={() => handleUpdateStatus(trip.id, 'In Progress')}
                                        >
                                            Start
                                        </Button>
                                        <Button
                                            variant="contained"
                                            color="secondary"
                                            onClick={() => handleCompleteTrip(trip.id)}
                                        >
                                            Complete
                                        </Button>
                                    </Stack>
                                )}
                            </Box>
                        </CardContent>
                    </Card>
                ))}
            </Box>

            <Dialog open={openCreateDialog} onClose={() => setOpenCreateDialog(false)} maxWidth="sm" fullWidth>
                <DialogTitle>Create New Trip</DialogTitle>
                <DialogContent>
                    <Stack spacing={3} sx={{ mt: 1 }}>
                        {hasErrors && (
                            <Alert severity="error">
                                {driversError && <div>Drivers: {driversError}</div>}
                                {vehiclesError && <div>Vehicles: {vehiclesError}</div>}
                            </Alert>
                        )}

                        <TextField
                            autoFocus
                            label="Trip Number"
                            fullWidth
                            value={newTrip.tripNumber}
                            onChange={(e) => setNewTrip({ ...newTrip, tripNumber: e.target.value })}
                            placeholder="Enter trip number (e.g., TRIP-001)"
                        />

                        <FormControl fullWidth>
                            <InputLabel>Driver</InputLabel>
                            <Select
                                value={newTrip.driverId}
                                label="Driver"
                                onChange={(e) => setNewTrip({ ...newTrip, driverId: e.target.value })}
                                disabled={driversLoading}
                            >
                                {driversLoading ? (
                                    <MenuItem disabled>
                                        <CircularProgress size={20} sx={{ mr: 1 }} />
                                        Loading drivers...
                                    </MenuItem>
                                ) : (
                                    drivers.map((driver) => (
                                        <MenuItem key={driver.id} value={driver.id}>
                                            {driver.name} - {driver.licenseNumber}
                                        </MenuItem>
                                    ))
                                )}
                            </Select>
                        </FormControl>

                        <FormControl fullWidth>
                            <InputLabel>Vehicle</InputLabel>
                            <Select
                                value={newTrip.vehicleId}
                                label="Vehicle"
                                onChange={(e) => setNewTrip({ ...newTrip, vehicleId: e.target.value })}
                                disabled={vehiclesLoading}
                            >
                                {vehiclesLoading ? (
                                    <MenuItem disabled>
                                        <CircularProgress size={20} sx={{ mr: 1 }} />
                                        Loading vehicles...
                                    </MenuItem>
                                ) : (
                                    vehicles.map((vehicle) => (
                                        <MenuItem key={vehicle.id} value={vehicle.id}>
                                            {vehicle.licensePlate} - {vehicle.model}
                                        </MenuItem>
                                    ))
                                )}
                            </Select>
                        </FormControl>
                    </Stack>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpenCreateDialog(false)} disabled={creating}>
                        Cancel
                    </Button>
                    <Button 
                        onClick={handleCreateTrip} 
                        color="primary" 
                        variant="contained"
                        disabled={!isFormValid || isLoading}
                        startIcon={creating ? <CircularProgress size={20} /> : null}
                    >
                        {creating ? 'Creating...' : 'Create Trip'}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default TripList; 