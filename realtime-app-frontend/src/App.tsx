import { CssBaseline, ThemeProvider, createTheme, AppBar, Toolbar, Typography, Container, Button } from '@mui/material';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import TripMonitor from './components/TripMonitor';
import TripList from './components/TripList';
import DirectionsCarIcon from '@mui/icons-material/DirectionsCar';
import MonitorIcon from '@mui/icons-material/Monitor';

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

function Navigation() {
  return (
    <AppBar position="static">
      <Toolbar>
        <DirectionsCarIcon sx={{ mr: 2 }} />
        <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
          Real-Time Trip Monitor
        </Typography>
        <Button 
          color="inherit" 
          component={Link} 
          to="/"
          startIcon={<DirectionsCarIcon />}
          sx={{ mr: 2 }}
        >
          Trips
        </Button>
        <Button 
          color="inherit" 
          component={Link} 
          to="/monitor"
          startIcon={<MonitorIcon />}
        >
          Monitor
        </Button>
      </Toolbar>
    </AppBar>
  );
}

function App() {
  return (
    <Router>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Navigation />
        <Container maxWidth="lg" sx={{ mt: 4 }}>
          <Routes>
            <Route path="/" element={<TripList />} />
            <Route path="/monitor" element={<TripMonitor />} />
          </Routes>
        </Container>
      </ThemeProvider>
    </Router>
  );
}

export default App; 