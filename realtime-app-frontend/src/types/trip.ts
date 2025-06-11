export interface Trip {
    id: string;
    tripNumber: string;
    status: string;
    startTime: string;
    endTime: string | null;
    driverId: string;
    vehicleId: string;
    lastModified: string;
    version: number;
}

export interface TripChangedEvent {
    tripId: string;
    tripNumber: string;
    status: string;
    lastModified: string;
    version: number;
    changeType: string;
}

export interface CreateTripRequest {
    tripNumber: string;
    driverId: string;
    vehicleId: string;
}

export interface UpdateTripStatusRequest {
    status: string;
} 