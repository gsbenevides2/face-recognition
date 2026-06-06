try{
    const response = await fetch('http://localhost:3000/api/api/healthcheck');
    if (response.ok) {
        console.log('Health check successful');
        process.exit(0);
    } else {
        console.error('Health check failed with status:', response.status);
        process.exit(1);
    }
}catch (error) {
    console.error('Health check failed with error:', error);
    process.exit(1);
}