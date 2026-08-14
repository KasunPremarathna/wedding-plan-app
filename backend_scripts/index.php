<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wedding Planner LK - API Server</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { 
            background-color: #1a2a3a; 
            color: white; 
            display: flex; 
            align-items: center; 
            justify-content: center; 
            height: 100vh; 
            margin: 0; 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        .text-gold { color: #d4af37; font-weight: 800; }
        .btn-gold { 
            background-color: #d4af37; 
            color: white; 
            border: none; 
            padding: 12px 35px; 
            font-weight: bold; 
            border-radius: 8px;
            text-decoration: none;
            transition: 0.3s;
        }
        .btn-gold:hover { 
            background-color: #b8962e; 
            color: white; 
        }
        .status-dot {
            height: 12px;
            width: 12px;
            background-color: #28a745;
            border-radius: 50%;
            display: inline-block;
            margin-right: 8px;
            box-shadow: 0 0 10px #28a745;
        }
    </style>
</head>
<body>
    <div class="text-center">
        <h1 class="text-gold mb-3">Wedding Planner LK</h1>
        <p class="lead mb-4"><span class="status-dot"></span> Backend Services & API are running successfully.</p>
        <a href="admin.php" class="btn btn-gold">Go to Admin Dashboard</a>
    </div>
</body>
</html>
