import * as signalR from '@microsoft/signalr';
import { TripChangedEvent } from '../types/trip';

class SignalRService {
    private connection: signalR.HubConnection | null = null;
    private onTripUpdateCallback: ((event: TripChangedEvent) => void) | null = null;

    public async startConnection(): Promise<void> {
        try {
            console.log('Starting SignalR connection to:', import.meta.env.VITE_SIGNALR_URL);
            
            this.connection = new signalR.HubConnectionBuilder()
                .withUrl(import.meta.env.VITE_SIGNALR_URL, {
                    skipNegotiation: false,
                    transport: signalR.HttpTransportType.WebSockets
                })
                .withAutomaticReconnect()
                .build();

            this.connection.on('ReceiveTripUpdate', (event: TripChangedEvent) => {
                console.log('Received trip update:', event);
                if (this.onTripUpdateCallback) {
                    this.onTripUpdateCallback(event);
                }
            });

            await this.connection.start();
            console.log('SignalR Connected successfully');
        } catch (err) {
            console.error('SignalR Connection Error:', err);
            throw err;
        }
    }

    public async joinTripGroup(tripNumber: string): Promise<void> {
        if (this.connection) {
            try {
                await this.connection.invoke('JoinTripGroup', tripNumber);
                console.log(`Joined trip group: ${tripNumber}`);
            } catch (err) {
                console.error('Error joining trip group: ', err);
            }
        }
    }

    public async leaveTripGroup(tripNumber: string): Promise<void> {
        if (this.connection) {
            try {
                await this.connection.invoke('LeaveTripGroup', tripNumber);
                console.log(`Left trip group: ${tripNumber}`);
            } catch (err) {
                console.error('Error leaving trip group: ', err);
            }
        }
    }

    public onTripUpdate(callback: (event: TripChangedEvent) => void): void {
        this.onTripUpdateCallback = callback;
    }

    public async stopConnection(): Promise<void> {
        if (this.connection) {
            try {
                await this.connection.stop();
                console.log('SignalR Disconnected.');
            } catch (err) {
                console.error('Error stopping SignalR connection: ', err);
            }
        }
    }
}

export const signalRService = new SignalRService(); 