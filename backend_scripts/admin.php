<?php
session_start();

$admin_password = "WeddingAdmin@2026!";

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
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        body { background-color: #f0f2f5; font-family: 'Segoe UI', sans-serif; }
        .navbar-brand { font-weight: bold; color: #d4af37 !important; font-size: 1.2rem; }
        .bg-navy { background-color: #1a2a3a; }
        .btn-gold { background-color: #d4af37; color: white; border: none; }
        .btn-gold:hover { background-color: #b8962e; color: white; }
        .badge-pending { background-color: #ffc107; color: #000; }
        .badge-approved { background-color: #28a745; color: #fff; }
        .badge-rejected { background-color: #dc3545; color: #fff; }
        .stat-card { border-radius: 12px; border: none; box-shadow: 0 2px 8px rgba(0,0,0,.08); }
        .stat-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 1.4rem; }
        .nav-pills .nav-link.active { background-color: #1a2a3a; }
        .nav-pills .nav-link { color: #1a2a3a; }
        .table th { font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; color: #6c757d; }
        .vendor-avatar { width: 38px; height: 38px; border-radius: 50%; background: linear-gradient(135deg, #d4af37, #b76e79); display: flex; align-items: center; justify-content: center; color: white; font-weight: 700; font-size: 16px; }
    </style>
</head>
<body>

<?php if (!$is_logged_in): ?>
    <div class="container mt-5 pt-5">
        <div class="row justify-content-center">
            <div class="col-md-4">
                <div class="card shadow border-0 rounded-4">
                    <div class="card-header bg-navy text-white text-center py-4 rounded-top-4">
                        <h4 class="mb-1">💍 Admin Login</h4>
                        <small class="text-white-50">Wedding Planner LK</small>
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
    <!-- Navbar -->
    <nav class="navbar navbar-expand-lg bg-navy navbar-dark shadow-sm">
        <div class="container">
            <a class="navbar-brand" href="#">💍 Wedding Planner LK Admin</a>
            <div class="d-flex align-items-center gap-2">
                <span class="text-white-50 small">Admin Panel</span>
                <a href="?logout=true" class="btn btn-outline-light btn-sm">Logout</a>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        <!-- Stats Row -->
        <div class="row g-3 mb-4" id="stats-row">
            <div class="col-6 col-md-3">
                <div class="card stat-card p-3">
                    <div class="d-flex align-items-center gap-3">
                        <div class="stat-icon" style="background:#fff3cd">⏳</div>
                        <div><div class="fw-bold fs-4" id="stat-pending">—</div><div class="text-muted small">Pending</div></div>
                    </div>
                </div>
            </div>
            <div class="col-6 col-md-3">
                <div class="card stat-card p-3">
                    <div class="d-flex align-items-center gap-3">
                        <div class="stat-icon" style="background:#d4edda">✅</div>
                        <div><div class="fw-bold fs-4" id="stat-approved">—</div><div class="text-muted small">Approved</div></div>
                    </div>
                </div>
            </div>
            <div class="col-6 col-md-3">
                <div class="card stat-card p-3">
                    <div class="d-flex align-items-center gap-3">
                        <div class="stat-icon" style="background:#f8d7da">❌</div>
                        <div><div class="fw-bold fs-4" id="stat-rejected">—</div><div class="text-muted small">Rejected</div></div>
                    </div>
                </div>
            </div>
            <div class="col-6 col-md-3">
                <div class="card stat-card p-3">
                    <div class="d-flex align-items-center gap-3">
                        <div class="stat-icon" style="background:#cce5ff">⚡</div>
                        <div><div class="fw-bold fs-4" id="stat-boosted">—</div><div class="text-muted small">Boosted</div></div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Tabs -->
        <ul class="nav nav-pills mb-3" id="adminTab">
            <li class="nav-item"><button class="nav-link active" onclick="switchTab('pending')">⏳ Pending Approvals</button></li>
            <li class="nav-item"><button class="nav-link" onclick="switchTab('approved')">✅ Approved Vendors</button></li>
            <li class="nav-item"><button class="nav-link" onclick="switchTab('rejected')">❌ Rejected</button></li>
        </ul>

        <!-- Table Card -->
        <div class="card shadow-sm border-0 rounded-4 overflow-hidden">
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="px-4 py-3">Vendor</th>
                                <th class="py-3">Category</th>
                                <th class="py-3">District</th>
                                <th class="py-3">Date</th>
                                <th class="py-3">Status</th>
                                <th class="py-3">Actions</th>
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

    <!-- Edit Vendor Modal -->
    <div class="modal fade" id="editVendorModal" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Edit Vendor Details</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body">
            <input type="hidden" id="edit-vendor-id">
            <div class="mb-3">
              <label class="form-label">Name</label>
              <input type="text" class="form-control" id="edit-vendor-name">
            </div>
            <div class="mb-3">
              <label class="form-label">Phone</label>
              <input type="text" class="form-control" id="edit-vendor-phone">
            </div>
            <div class="mb-3">
              <label class="form-label">Category</label>
              <input type="text" class="form-control" id="edit-vendor-category">
            </div>
            <div class="mb-3">
              <label class="form-label">District</label>
              <input type="text" class="form-control" id="edit-vendor-district">
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-primary" id="btn-save-vendor">Save Changes</button>
          </div>
        </div>
      </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

    <script type="module">
        import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.1/firebase-app.js";
        import { getFirestore, collection, query, where, getDocs, doc, updateDoc, orderBy } from "https://www.gstatic.com/firebasejs/10.8.1/firebase-firestore.js";

        const firebaseConfig = {
            apiKey: "AIzaSyCHnF7z_X9hGt8KNpNlzkKmAVCUhU7M3pg",
            projectId: "wedding-planner-lk",
            storageBucket: "wedding-planner-lk.firebasestorage.app",
        };

        const app = initializeApp(firebaseConfig);
        const db = getFirestore(app);

        let currentTab = 'pending';
        let allVendorsData = {}; // Store data for editing

        window.switchTab = function(tab) {
            currentTab = tab;
            document.querySelectorAll('#adminTab .nav-link').forEach(b => b.classList.remove('active'));
            event.target.classList.add('active');
            loadVendors(tab);
        }

        async function loadStats() {
            const statuses = ['pending', 'approved', 'rejected'];
            for (const s of statuses) {
                const snap = await getDocs(query(collection(db, 'vendor_registrations'), where('status', '==', s)));
                document.getElementById('stat-' + s).textContent = snap.size;
            }
            const boostedSnap = await getDocs(query(collection(db, 'vendor_registrations'), where('is_boosted', '==', true)));
            document.getElementById('stat-boosted').textContent = boostedSnap.size;
        }

        async function loadVendors(status) {
            const tbody = document.getElementById('vendor-table-body');
            tbody.innerHTML = '<tr><td colspan="6" class="text-center py-4"><div class="spinner-border text-primary" role="status"></div> Loading...</td></tr>';

            try {
                const q = query(collection(db, 'vendor_registrations'), where('status', '==', status));
                const snap = await getDocs(q);

                tbody.innerHTML = '';

                if (snap.empty) {
                    tbody.innerHTML = `<tr><td colspan="6" class="text-center py-4 text-muted">No ${status} vendors found.</td></tr>`;
                    return;
                }

                snap.forEach((document) => {
                    const v = document.data();
                    const id = document.id;
                    let dateStr = 'N/A';
                    if (v.timestamp) {
                        dateStr = v.timestamp.toDate().toLocaleDateString('en-GB');
                    }

                    const initials = (v.name || '?')[0].toUpperCase();
                    const isBoosted = v.is_boosted === true;

                    const tr = window.document.createElement('tr');
                    tr.innerHTML = `
                        <td class="px-4">
                            <div class="d-flex align-items-center gap-2">
                                <div class="vendor-avatar">${initials}</div>
                                <div>
                                    <div class="fw-bold">${v.name || 'N/A'}</div>
                                    <div class="text-muted small">${v.email || ''}</div>
                                </div>
                            </div>
                        </td>
                        <td><span class="badge badge-pending px-2 py-1">${v.category || 'N/A'}</span></td>
                        <td>${v.district || 'N/A'}</td>
                        <td>${dateStr}</td>
                        <td>
                            ${isBoosted ? '<span class="badge bg-warning text-dark me-1">⚡ Boosted</span>' : ''}
                            <span class="badge badge-${status}">${status}</span>
                        </td>
                        <td>
                            <div class="d-flex gap-2 flex-wrap">
                                <button class="btn btn-info btn-sm text-white action-edit" data-id="${id}">✏️ Edit</button>
                                ${status === 'pending' ? `
                                    <button class="btn btn-success btn-sm action-approve" data-id="${id}">✅ Approve</button>
                                    <button class="btn btn-danger btn-sm action-reject" data-id="${id}">❌ Reject</button>
                                ` : ''}
                                ${status === 'approved' ? `
                                    <button class="btn btn-sm ${isBoosted ? 'btn-warning' : 'btn-outline-warning'} action-boost" data-id="${id}" data-boosted="${isBoosted}">
                                        ${isBoosted ? '⚡ Unboost' : '⚡ Boost'}
                                    </button>
                                    <button class="btn btn-danger btn-sm action-reject" data-id="${id}">❌ Reject</button>
                                ` : ''}
                                ${status === 'rejected' ? `
                                    <button class="btn btn-success btn-sm action-approve" data-id="${id}">↩️ Re-approve</button>
                                ` : ''}
                            </div>
                        </td>
                    `;
                    tbody.appendChild(tr);
                    
                    // Store for edit modal
                    allVendorsData[id] = v;
                });

                // Attach events
                document.querySelectorAll('.action-approve').forEach(btn => {
                    btn.addEventListener('click', async (e) => {
                        const id = e.target.getAttribute('data-id');
                        if (confirm('Approve this vendor?')) {
                            await updateDoc(doc(db, 'vendor_registrations', id), { status: 'approved' });
                            alert('✅ Vendor approved!');
                            await loadVendors(currentTab);
                            loadStats();
                        }
                    });
                });

                document.querySelectorAll('.action-reject').forEach(btn => {
                    btn.addEventListener('click', async (e) => {
                        const id = e.target.getAttribute('data-id');
                        const reason = prompt('Rejection reason (optional, shown to vendor):');
                        if (reason === null) return; // User pressed Cancel
                        if (confirm('Reject this vendor?')) {
                            await updateDoc(doc(db, 'vendor_registrations', id), {
                                status: 'rejected',
                                rejection_reason: reason || '',
                                rejected_at: new Date().toISOString(),
                            });
                            alert('❌ Vendor rejected.');
                            await loadVendors(currentTab);
                            loadStats();
                        }
                    });
                });

                document.querySelectorAll('.action-boost').forEach(btn => {
                    btn.addEventListener('click', async (e) => {
                        const id = e.target.getAttribute('data-id');
                        const isBoosted = e.target.getAttribute('data-boosted') === 'true';
                        const newBoost = !isBoosted;
                        await updateDoc(doc(db, 'vendor_registrations', id), {
                            is_boosted: newBoost,
                            boost_badge: newBoost ? '⚡ TOP' : '',
                        });
                        alert(newBoost ? '⚡ Vendor boosted!' : 'Boost removed.');
                        await loadVendors(currentTab);
                        loadStats();
                    });
                });

                document.querySelectorAll('.action-edit').forEach(btn => {
                    btn.addEventListener('click', (e) => {
                        const id = e.target.getAttribute('data-id');
                        const v = allVendorsData[id];
                        document.getElementById('edit-vendor-id').value = id;
                        document.getElementById('edit-vendor-name').value = v.name || '';
                        document.getElementById('edit-vendor-phone').value = v.phone || '';
                        document.getElementById('edit-vendor-category').value = v.category || '';
                        document.getElementById('edit-vendor-district').value = v.district || '';
                        const modal = new bootstrap.Modal(document.getElementById('editVendorModal'));
                        modal.show();
                    });
                });

            } catch (error) {
                console.error(error);
                tbody.innerHTML = `<tr><td colspan="6" class="text-danger text-center py-4">Error: ${error.message}</td></tr>`;
            }
        }

        // Initial load
        loadVendors('pending');
        loadStats();
        
        document.getElementById('btn-save-vendor').addEventListener('click', async () => {
            const id = document.getElementById('edit-vendor-id').value;
            const btn = document.getElementById('btn-save-vendor');
            btn.innerHTML = 'Saving...';
            btn.disabled = true;
            try {
                await updateDoc(doc(db, 'vendor_registrations', id), {
                    name: document.getElementById('edit-vendor-name').value,
                    phone: document.getElementById('edit-vendor-phone').value,
                    category: document.getElementById('edit-vendor-category').value,
                    district: document.getElementById('edit-vendor-district').value,
                });
                alert('Vendor details updated successfully!');
                const modal = bootstrap.Modal.getInstance(document.getElementById('editVendorModal'));
                modal.hide();
                await loadVendors(currentTab);
            } catch (e) {
                alert('Error updating: ' + e.message);
            }
            btn.innerHTML = 'Save Changes';
            btn.disabled = false;
        });
    </script>
<?php endif; ?>
</body>
</html>
