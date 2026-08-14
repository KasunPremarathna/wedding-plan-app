<?php
session_start();

// Admin Authentication Password (Change this to a secure password!)
$admin_password = "password123";

if (isset($_POST['password'])) {
    if ($_POST['password'] === $admin_password) {
        $_SESSION['admin_logged_in'] = true;
    } else {
        $error = "වැරදි පාස්වර්ඩ් එකකි! (Invalid Password)";
    }
}

if (isset($_GET['logout'])) {
    session_destroy();
    header("Location: admin.php");
    exit();
}

$is_logged_in = isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true;
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wedding Planner LK - Admin Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8f9fa; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        .navbar-brand { font-weight: bold; color: #d4af37 !important; }
        .bg-navy { background-color: #1a2a3a; }
        .badge-pending { background-color: #ffc107; color: #000; }
        .btn-gold { background-color: #d4af37; color: white; border: none; }
        .btn-gold:hover { background-color: #b8962e; color: white; }
    </style>
</head>
<body>

<?php if (!$is_logged_in): ?>
    <div class="container mt-5 pt-5">
        <div class="row justify-content-center">
            <div class="col-md-4">
                <div class="card shadow border-0 rounded-4">
                    <div class="card-header bg-navy text-white text-center py-4 rounded-top-4">
                        <h4 class="mb-0">Admin Login</h4>
                    </div>
                    <div class="card-body p-4">
                        <?php if (isset($error)): ?>
                            <div class="alert alert-danger"><?= $error ?></div>
                        <?php endif; ?>
                        <form method="POST">
                            <div class="mb-4">
                                <label class="form-label text-muted">Password</label>
                                <input type="password" name="password" class="form-control form-control-lg" required placeholder="Enter admin password">
                            </div>
                            <button type="submit" class="btn btn-gold btn-lg w-100">Login</button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
<?php else: ?>
    <!-- Admin Dashboard Content -->
    <nav class="navbar navbar-expand-lg bg-navy navbar-dark shadow-sm">
        <div class="container">
            <a class="navbar-brand" href="#">Wedding Planner LK Admin</a>
            <div class="d-flex">
                <a href="?logout=true" class="btn btn-outline-light btn-sm">Logout</a>
            </div>
        </div>
    </nav>

    <div class="container mt-5">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h3 class="mb-0 text-navy">Pending Vendor Registrations</h3>
            <button class="btn btn-outline-primary btn-sm" onclick="loadPendingVendors()">Refresh List</button>
        </div>
        
        <div class="card shadow-sm border-0 rounded-4 overflow-hidden">
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="px-4 py-3">Name</th>
                                <th class="py-3">Email</th>
                                <th class="py-3">Phone</th>
                                <th class="py-3">Service</th>
                                <th class="py-3">Date</th>
                                <th class="py-3">Action</th>
                            </tr>
                        </thead>
                        <tbody id="vendor-table-body">
                            <tr><td colspan="6" class="text-center py-4"><div class="spinner-border text-primary" role="status"></div> Loading...</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Firebase JS SDK setup -->
    <script type="module">
        import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.1/firebase-app.js";
        import { getFirestore, collection, query, where, getDocs, doc, updateDoc } from "https://www.gstatic.com/firebasejs/10.8.1/firebase-firestore.js";

        // Firebase Configuration (From google-services.json)
        const firebaseConfig = {
            apiKey: "AIzaSyCHnF7z_X9hGt8KNpNlzkKmAVCUhU7M3pg",
            projectId: "wedding-planner-lk",
            storageBucket: "wedding-planner-lk.firebasestorage.app",
        };

        // Initialize Firebase
        const app = initializeApp(firebaseConfig);
        const db = getFirestore(app);

        // Make function globally available so the refresh button works
        window.loadPendingVendors = async function() {
            const tableBody = document.getElementById('vendor-table-body');
            tableBody.innerHTML = '<tr><td colspan="6" class="text-center py-4"><div class="spinner-border text-primary" role="status"></div> Loading...</td></tr>';
            
            try {
                const q = query(collection(db, "vendor_registrations"), where("status", "==", "pending"));
                const querySnapshot = await getDocs(q);
                
                tableBody.innerHTML = '';
                
                if (querySnapshot.empty) {
                    tableBody.innerHTML = '<tr><td colspan="6" class="text-center py-4 text-muted">No pending vendor registrations found.</td></tr>';
                    return;
                }

                querySnapshot.forEach((document) => {
                    const vendor = document.data();
                    const vendorId = document.id;
                    let dateStr = 'N/A';
                    if (vendor.timestamp) {
                        const dateObj = vendor.timestamp.toDate();
                        dateStr = dateObj.toLocaleDateString() + ' ' + dateObj.toLocaleTimeString();
                    }
                    
                    const tr = window.document.createElement('tr');
                    tr.innerHTML = `
                        <td class="px-4 fw-bold">${vendor.name || 'N/A'}</td>
                        <td>${vendor.email || 'N/A'}</td>
                        <td>${vendor.phone || 'N/A'}</td>
                        <td><span class="badge badge-pending px-2 py-1">${vendor.service || 'N/A'}</span></td>
                        <td>${dateStr}</td>
                        <td>
                            <button class="btn btn-success btn-sm approve-btn shadow-sm" data-id="${vendorId}">
                                Approve Vendor
                            </button>
                        </td>
                    `;
                    tableBody.appendChild(tr);
                });

                // Attach event listeners to approve buttons
                window.document.querySelectorAll('.approve-btn').forEach(btn => {
                    btn.addEventListener('click', async (e) => {
                        const id = e.target.getAttribute('data-id');
                        if (confirm('මෙම Vendor ව Approve කරන්න ඔබට විශ්වාසද? (Are you sure?)')) {
                            await approveVendor(id);
                        }
                    });
                });

            } catch (error) {
                console.error("Error fetching vendors:", error);
                tableBody.innerHTML = `<tr><td colspan="6" class="text-danger text-center py-4">Error loading data: ${error.message}<br>Make sure Firestore rules allow read access.</td></tr>`;
            }
        }

        async function approveVendor(vendorId) {
            try {
                const vendorRef = doc(db, "vendor_registrations", vendorId);
                await updateDoc(vendorRef, {
                    status: "approved"
                });
                alert("Vendor අනුමත කිරීම සාර්ථකයි! (Successfully approved)");
                loadPendingVendors(); // Reload the table
            } catch (error) {
                console.error("Error approving vendor:", error);
                alert("Vendor අනුමත කිරීම අසාර්ථකයි! (Failed): " + error.message);
            }
        }

        // Load data on page load
        loadPendingVendors();
    </script>
<?php endif; ?>
</body>
</html>
