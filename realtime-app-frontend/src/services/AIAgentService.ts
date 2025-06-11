import { HubConnection, HubConnectionBuilder, HttpTransportType } from '@microsoft/signalr';
import { Trip } from '../types/trip';

export interface AIAnalysis {
    timestamp: string;
    tripNumber: string;
    status: string;
    recommendations: string[];
    confidence: number;
    analysisType: 'demo' | 'production';
}

/**
 * AI Agent Service - DEMO/POC Implementation
 * 
 * This is a proof-of-concept demonstration of AI-powered trip monitoring.
 * In a production environment, this would integrate with actual AI/ML services
 * such as Azure OpenAI, Azure Machine Learning, or other AI platforms.
 * 
 * Current capabilities (Demo):
 * - Real-time trip monitoring via SignalR
 * - Simulated AI analysis and recommendations
 * - Pattern-based recommendation generation
 */
export class AIAgentService {
    private connection: HubConnection;
    private currentTrip: Trip | null = null;
    private isMonitoring: boolean = false;
    private analysisCallbacks: ((analysis: AIAnalysis) => void)[] = [];

    constructor() {
        console.log('[DEMO AI] Initializing AI Agent Service (POC)');
        console.log('[DEMO AI] SignalR URL:', import.meta.env.VITE_SIGNALR_URL || 'http://localhost:5000/tripHub');
        
        this.connection = new HubConnectionBuilder()
            .withUrl(import.meta.env.VITE_SIGNALR_URL || 'http://localhost:5000/tripHub', {
                skipNegotiation: false,
                transport: HttpTransportType.WebSockets
            })
            .withAutomaticReconnect()
            .build();
    }

    public async startMonitoring(tripNumber: string): Promise<void> {
        if (this.isMonitoring) {
            await this.stopMonitoring();
        }

        try {
            console.log('Starting SignalR connection...');
            await this.connection.start();
            console.log('SignalR connected successfully');
            
            console.log('Joining trip group:', tripNumber);
            await this.connection.invoke('JoinTripGroup', tripNumber);
            console.log('Successfully joined trip group');
            
            this.isMonitoring = true;

            this.connection.on('ReceiveTripUpdate', (trip: Trip) => {
                console.log('Received trip update:', trip);
                this.currentTrip = trip;
                this.analyzeTrip(trip);
            });
        } catch (error) {
            console.error('Error starting trip monitoring:', error);
            this.isMonitoring = false;
            throw error;
        }
    }

    public async stopMonitoring(): Promise<void> {
        if (this.currentTrip) {
            await this.connection.invoke('LeaveTripGroup', this.currentTrip.tripNumber);
        }
        await this.connection.stop();
        this.isMonitoring = false;
        this.currentTrip = null;
    }

    /**
     * Subscribe to AI analysis updates
     * In production, this would provide real-time AI insights
     */
    public onAnalysis(callback: (analysis: AIAnalysis) => void): void {
        this.analysisCallbacks.push(callback);
    }

    private analyzeTrip(trip: Trip): void {
        // Simulate AI analysis of trip data (DEMO IMPLEMENTATION)
        const analysis: AIAnalysis = {
            timestamp: new Date().toISOString(),
            tripNumber: trip.tripNumber,
            status: trip.status,
            recommendations: this.generateRecommendations(trip),
            confidence: Math.random() * 0.3 + 0.7, // Simulate 70-100% confidence
            analysisType: 'demo'
        };

        console.log('[DEMO AI] Analysis Generated:', analysis);
        
        // Notify subscribers
        this.analysisCallbacks.forEach(callback => callback(analysis));
    }

    private generateRecommendations(trip: Trip): string[] {
        const recommendations: string[] = [];

        // Simulate AI recommendations based on trip status (DEMO LOGIC)
        switch (trip.status.toLowerCase()) {
            case 'delayed':
                recommendations.push('🚦 Consider rerouting to avoid traffic congestion');
                recommendations.push('📱 Notify customer about estimated delay');
                recommendations.push('⚡ Increase priority for this trip');
                break;
            case 'in_progress':
                recommendations.push('⛽ Monitor fuel consumption patterns');
                recommendations.push('🗺️ Check for optimal route alternatives');
                recommendations.push('🎯 ETA looks good, maintain current pace');
                break;
            case 'completed':
                recommendations.push('🔧 Schedule vehicle maintenance check');
                recommendations.push('📊 Update driver performance metrics');
                recommendations.push('⭐ Trip completed successfully');
                break;
            case 'created':
                recommendations.push('🚀 Ready to start trip');
                recommendations.push('✅ All systems optimal');
                break;
            default:
                recommendations.push('👀 Continue monitoring trip status');
                recommendations.push('📈 Analyzing trip patterns...');
        }

        // Add some random demo recommendations for variety
        const additionalRecommendations = [
            '🌡️ Weather conditions are favorable',
            '📊 Traffic patterns analyzed',
            '🔋 Vehicle diagnostics normal',
            '👥 Customer satisfaction probability: High'
        ];

        // Randomly add 1-2 additional recommendations
        const additionalCount = Math.floor(Math.random() * 2) + 1;
        for (let i = 0; i < additionalCount; i++) {
            const randomRec = additionalRecommendations[Math.floor(Math.random() * additionalRecommendations.length)];
            if (!recommendations.includes(randomRec)) {
                recommendations.push(randomRec);
            }
        }

        return recommendations;
    }

    /**
     * Get the current AI analysis (for demo purposes)
     */
    public getCurrentAnalysis(): AIAnalysis | null {
        if (!this.currentTrip) return null;
        
        return {
            timestamp: new Date().toISOString(),
            tripNumber: this.currentTrip.tripNumber,
            status: this.currentTrip.status,
            recommendations: this.generateRecommendations(this.currentTrip),
            confidence: Math.random() * 0.3 + 0.7,
            analysisType: 'demo'
        };
    }
} 