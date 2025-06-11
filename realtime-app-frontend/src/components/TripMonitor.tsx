import React, { useEffect, useState } from 'react';
import { Box, Typography, Card, CardContent, Stack } from '@mui/material';
import TripDetails from './TripDetails';
import TripControls from './TripControls';
import AIRecommendations from './AIRecommendations';
import { Trip } from '../types/trip';
import { signalRService } from '../services/signalRService';
import { apiService } from '../services/apiService';
import { AIAgentService } from '../services/AIAgentService';

const TripMonitor: React.FC = () => {
    const [selectedTrip, setSelectedTrip] = useState<Trip | null>(null);
    const [trips, setTrips] = useState<Trip[]>([]);
    const [isMonitoring, setIsMonitoring] = useState(false);
    const [recommendations, setRecommendations] = useState<string[]>([]);
    const [aiAgent] = useState(new AIAgentService());

    useEffect(() => {
        loadTrips();
        setupSignalR();
        setupAI();
        return () => {
            signalRService.stopConnection();
            if (isMonitoring) {
                aiAgent.stopMonitoring();
            }
        };
    }, []);

    const loadTrips = async () => {
        try {
            const loadedTrips = await apiService.getAllTrips();
            setTrips(loadedTrips);
            if (loadedTrips.length > 0 && !selectedTrip) {
                setSelectedTrip(loadedTrips[0]);
            }
        } catch (error) {
            console.error('Error loading trips:', error);
        }
    };

    const setupSignalR = async () => {
        await signalRService.startConnection();
        signalRService.onTripUpdate((updatedTrip: any) => {
            setTrips(prevTrips => 
                prevTrips.map(trip => 
                    trip.id === updatedTrip.tripId ? { ...trip, ...updatedTrip } : trip
                )
            );
            
            if (selectedTrip && selectedTrip.id === updatedTrip.tripId) {
                setSelectedTrip(prev => prev ? { ...prev, ...updatedTrip } : null);
            }
        });
    };

    const setupAI = () => {
        aiAgent.onAnalysis((analysis) => {
            setRecommendations(analysis.recommendations);
        });
    };

    const handleStartMonitoring = async (tripNumber: string) => {
        try {
            await aiAgent.startMonitoring(tripNumber);
            setIsMonitoring(true);
        } catch (error) {
            console.error('Failed to start AI monitoring:', error);
            throw error;
        }
    };

    const handleStopMonitoring = async () => {
        try {
            await aiAgent.stopMonitoring();
            setIsMonitoring(false);
            setRecommendations([]);
        } catch (error) {
            console.error('Failed to stop AI monitoring:', error);
        }
    };

    return (
        <Box sx={{ p: 3 }}>
            <Typography variant="h4" gutterBottom>
                Trip Monitor
            </Typography>
            
            <Stack direction={{ xs: 'column', md: 'row' }} spacing={3}>
                <Box sx={{ flexGrow: 1 }}>
                    <Card>
                        <CardContent>
                            <TripDetails trip={selectedTrip} />
                        </CardContent>
                    </Card>
                </Box>
                
                <Box sx={{ width: { xs: '100%', md: '400px' } }}>
                    <Card>
                        <CardContent>
                            <AIRecommendations recommendations={recommendations} />
                        </CardContent>
                    </Card>
                    
                    <Box sx={{ mt: 3 }}>
                        <Card>
                            <CardContent>
                                <TripControls 
                                    onStartMonitoring={handleStartMonitoring}
                                    onStopMonitoring={handleStopMonitoring}
                                    isMonitoring={isMonitoring}
                                />
                            </CardContent>
                        </Card>
                    </Box>
                    
                    <Box sx={{ mt: 3 }}>
                        <Card>
                            <CardContent>
                                <Typography variant="h6" gutterBottom>
                                    Trip Selection
                                </Typography>
                                <Stack spacing={1}>
                                    {trips.map((trip) => (
                                        <Box
                                            key={trip.id}
                                            sx={{
                                                p: 2,
                                                border: '1px solid',
                                                borderColor: selectedTrip?.id === trip.id ? 'primary.main' : 'grey.300',
                                                borderRadius: 1,
                                                cursor: 'pointer',
                                                bgcolor: selectedTrip?.id === trip.id ? 'primary.50' : 'transparent',
                                                '&:hover': {
                                                    bgcolor: selectedTrip?.id === trip.id ? 'primary.100' : 'grey.50'
                                                }
                                            }}
                                            onClick={() => setSelectedTrip(trip)}
                                        >
                                            <Typography variant="subtitle2">
                                                Trip #{trip.tripNumber}
                                            </Typography>
                                            <Typography variant="body2" color="text.secondary">
                                                Status: {trip.status}
                                            </Typography>
                                        </Box>
                                    ))}
                                </Stack>
                            </CardContent>
                        </Card>
                    </Box>
                </Box>
            </Stack>
        </Box>
    );
};

export default TripMonitor; 