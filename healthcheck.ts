fetch('http://localhost:3000/api/healthcheck')
    .then(r => r.status === 200 ? process.exit(0) : process.exit(1)).catch(()=>process.exit(1))