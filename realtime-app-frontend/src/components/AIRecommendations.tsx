import React from 'react';
import { Box, Typography, List, ListItem, ListItemIcon, ListItemText } from '@mui/material';
import SmartToyIcon from '@mui/icons-material/SmartToy';

interface AIRecommendationsProps {
    recommendations: string[];
}

const AIRecommendations: React.FC<AIRecommendationsProps> = ({ recommendations }) => {
    if (recommendations.length === 0) {
        return (
            <Box>
                <Typography variant="h6" gutterBottom>
                    AI Recommendations
                </Typography>
                <Typography variant="body2" color="text.secondary">
                    No recommendations available
                </Typography>
            </Box>
        );
    }

    return (
        <Box>
            <Typography variant="h6" gutterBottom>
                AI Recommendations
            </Typography>
            <List>
                {recommendations.map((recommendation, index) => (
                    <ListItem key={index}>
                        <ListItemIcon>
                            <SmartToyIcon color="primary" />
                        </ListItemIcon>
                        <ListItemText 
                            primary={recommendation}
                            primaryTypographyProps={{
                                variant: 'body2'
                            }}
                        />
                    </ListItem>
                ))}
            </List>
        </Box>
    );
};

export default AIRecommendations; 