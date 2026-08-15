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
            <li class="nav-item"><button class="nav-link" onclick="switchTab('sponsored')">🌟 Sponsored Banners</button></li>
        </ul>

        <!-- Vendors Table Card -->
        <div class="card shadow-sm border-0 rounded-4 overflow-hidden" id="vendor-table-card">
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="px-4 py-3">Vendor</th>
                                <th class="py-3">Category</th>
                                <th class="py-3">District</th>
                                <th class="py-3">Analytics & Views</th>
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

        <!-- Sponsored Banners Container -->
        <div class="d-none" id="sponsored-container">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h5 class="fw-bold m-0">🌟 Active Sponsored Banners</h5>
                <button class="btn btn-gold" onclick="openSponsoredModal()">➕ Add New Banner</button>
            </div>
            <div class="card shadow-sm border-0 rounded-4 overflow-hidden">
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover align-middle mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th class="px-4 py-3">Banner Image</th>
                                    <th class="py-3">Title</th>
                                    <th class="py-3">Subtitle</th>
                                    <th class="py-3">Link URL</th>
                                    <th class="py-3">Actions</th>
                                </tr>
                            </thead>
                            <tbody id="sponsored-table-body">
                                <tr><td colspan="5" class="text-center py-4"><div class="spinner-border text-warning" role="status"></div> Loading Banners...</td></tr>
                            </tbody>
                        </table>
                    </div>
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

    <!-- Add/Edit Sponsored Banner Modal -->
    <div class="modal fade" id="sponsoredModal" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
          <div class="modal-header bg-navy text-white">
            <h5 class="modal-title">🌟 Setup Sponsored Banner</h5>
            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body">
            <input type="hidden" id="banner-id">
            <div class="mb-3">
              <label class="form-label fw-bold">Banner Image</label>
              <input type="file" class="form-control mb-2" id="banner-file" accept="image/*">
              <input type="text" class="form-control" id="banner-image-url" placeholder="Or enter image URL directly (http...)">
              <small class="text-muted">Recommended aspect ratio: 16:9 or 2:1</small>
            </div>
            <div class="mb-3">
              <label class="form-label fw-bold">Banner Title</label>
              <input type="text" class="form-control" id="banner-title" placeholder="e.g. Grand Pearl Hotel">
            </div>
            <div class="mb-3">
              <label class="form-label fw-bold">Banner Subtitle</label>
              <input type="text" class="form-control" id="banner-subtitle" placeholder="e.g. Luxury Wedding Venues • Colombo">
            </div>
            <div class="mb-3">
              <label class="form-label fw-bold">Target Link / Vendor ID</label>
              <input type="text" class="form-control" id="banner-link-url" placeholder="e.g. https://... or vendor ID">
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-gold" id="btn-save-banner">Save Banner</button>
          </div>
        </div>
      </div>
    <!-- Vendor Analytics Detail Modal -->
    <div class="modal fade" id="vendorAnalyticsModal" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content">
          <div class="modal-header bg-dark text-white">
            <h5 class="modal-title" id="analytics-vendor-name">📊 Vendor Analytics Report</h5>
            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body p-4">
            <div class="row g-3 mb-4">
              <div class="col-6 col-md-3">
                <div class="p-3 border rounded-3 bg-light text-center">
                  <div class="fs-4 fw-bold text-primary" id="analytics-views">0</div>
                  <div class="small text-muted">👁️ Profile Views</div>
                </div>
              </div>
              <div class="col-6 col-md-3">
                <div class="p-3 border rounded-3 bg-light text-center">
                  <div class="fs-4 fw-bold text-purple" style="color:#6f42c1" id="analytics-pkg-views">0</div>
                  <div class="small text-muted">📄 Package Views</div>
                </div>
              </div>
              <div class="col-6 col-md-3">
                <div class="p-3 border rounded-3 bg-light text-center">
                  <div class="fs-4 fw-bold text-success" id="analytics-inquiries">0</div>
                  <div class="small text-muted">💬 Inquiries</div>
                </div>
              </div>
              <div class="col-6 col-md-3">
                <div class="p-3 border rounded-3 bg-light text-center">
                  <div class="fs-4 fw-bold text-danger" id="analytics-favorites">0</div>
                  <div class="small text-muted">⭐ Favorites</div>
                </div>
              </div>
            </div>

            <h6 class="fw-bold mb-3">📅 Monthly Analytics Summary</h6>
            <div class="table-responsive border rounded-3">
              <table class="table table-sm align-middle mb-0">
                <thead class="table-light">
                  <tr>
                    <th>Month / Timeframe</th>
                    <th>Profile Views</th>
                    <th>Package Views</th>
                    <th>Inquiries</th>
                  </tr>
                </thead>
                <tbody id="analytics-monthly-tbody">
                  <tr><td colspan="4" class="text-center text-muted py-3">Loading logs...</td></tr>
                </tbody>
              </table>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
          </div>
        </div>
      </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

    <script type="module">
        import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.1/firebase-app.js";
        import { getFirestore, collection, query, where, getDocs, doc, updateDoc, addDoc, deleteDoc, orderBy } from "https://www.gstatic.com/firebasejs/10.8.1/firebase-firestore.js";

        const firebaseConfig = {
            apiKey: "AIzaSyCHnF7z_X9hGt8KNpNlzkKmAVCUhU7M3pg",
            projectId: "wedding-planner-lk",
            storageBucket: "wedding-planner-lk.firebasestorage.app",
        };

        const app = initializeApp(firebaseConfig);
        const db = getFirestore(app);

        let currentTab = 'pending';
        let allVendorsData = {};

        window.switchTab = function(tab) {
            currentTab = tab;
            document.querySelectorAll('#adminTab .nav-link').forEach(b => b.classList.remove('active'));
            if (event) event.target.classList.add('active');

            const vendorCard = document.getElementById('vendor-table-card');
            const sponsoredCard = document.getElementById('sponsored-container');

            if (tab === 'sponsored') {
                vendorCard.classList.add('d-none');
                sponsoredCard.classList.remove('d-none');
                loadSponsoredBanners();
            } else {
                sponsoredCard.classList.add('d-none');
                vendorCard.classList.remove('d-none');
                loadVendors(tab);
            }
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
                        <td>
                            <div class="small fw-bold text-dark">👁️ ${v.profile_views || 0} views</div>
                            <div class="small text-muted">📄 ${v.package_views || 0} pkgs • 💬 ${v.inquiries_count || 0} inq</div>
                        </td>
                        <td>${dateStr}</td>
                        <td>
                            ${isBoosted ? '<span class="badge bg-warning text-dark me-1">⚡ Boosted</span>' : ''}
                            <span class="badge badge-${status}">${status}</span>
                        </td>
                        <td>
                            <div class="d-flex gap-2 flex-wrap">
                                <button class="btn btn-dark btn-sm action-stats" data-id="${id}">📊 Stats</button>
                                <button class="btn btn-info btn-sm text-white action-edit" data-id="${id}">✏️ Edit</button>
                                ${status === 'pending' ? `
                                    <button class="btn btn-success btn-sm action-approve" data-id="${id}">✅ Approve</button>
                                    <button class="btn btn-danger btn-sm action-reject" data-id="${id}">❌ Reject</button>
                                ` : ''}
                                ${status === 'approved' ? `
                                    <button class="btn btn-sm ${isBoosted ? 'btn-warning' : 'btn-outline-warning'} action-boost" data-id="${id}" data-boosted="${isBoosted}">
                                        ${isBoosted ? '⚡ Unboost' : '⚡ Boost'}
                                    </button>
                                    <button class="btn btn-sm btn-outline-primary action-sponsor" data-id="${id}">🌟 Sponsor</button>
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
                        if (reason === null) return;
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

                document.querySelectorAll('.action-stats').forEach(btn => {
                    btn.addEventListener('click', (e) => {
                        const id = e.target.getAttribute('data-id');
                        const v = allVendorsData[id];
                        openVendorAnalyticsModal(id, v);
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

                document.querySelectorAll('.action-sponsor').forEach(btn => {
                    btn.addEventListener('click', (e) => {
                        const id = e.target.getAttribute('data-id');
                        const v = allVendorsData[id];
                        openSponsoredModalWithVendor(id, v);
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

        // ============================================================
        // SPONSORED BANNERS LOGIC
        // ============================================================
        async function loadSponsoredBanners() {
            const tbody = document.getElementById('sponsored-table-body');
            tbody.innerHTML = '<tr><td colspan="5" class="text-center py-4"><div class="spinner-border text-warning" role="status"></div> Loading Banners...</td></tr>';

            try {
                const snap = await getDocs(collection(db, 'sponsored_banners'));
                tbody.innerHTML = '';

                if (snap.empty) {
                    tbody.innerHTML = '<tr><td colspan="5" class="text-center py-4 text-muted">No sponsored banners active. Click "Add New Banner" to create one.</td></tr>';
                    return;
                }

                snap.forEach((document) => {
                    const b = document.data();
                    const id = document.id;

                    const tr = window.document.createElement('tr');
                    tr.innerHTML = `
                        <td class="px-4">
                            <img src="${b.image_url || 'https://via.placeholder.com/120x60'}" style="width:100px; height:50px; object-fit:cover; border-radius:8px;" alt="Banner">
                        </td>
                        <td><div class="fw-bold">${b.title || 'N/A'}</div></td>
                        <td><small class="text-muted">${b.subtitle || ''}</small></td>
                        <td><small class="text-primary">${b.link_url || 'N/A'}</small></td>
                        <td>
                            <button class="btn btn-danger btn-sm action-delete-banner" data-id="${id}">🗑️ Delete</button>
                        </td>
                    `;
                    tbody.appendChild(tr);
                });

                document.querySelectorAll('.action-delete-banner').forEach(btn => {
                    btn.addEventListener('click', async (e) => {
                        const id = e.target.getAttribute('data-id');
                        if (confirm('Delete this sponsored banner?')) {
                            await deleteDoc(doc(db, 'sponsored_banners', id));
                            alert('🗑️ Banner deleted successfully!');
                            loadSponsoredBanners();
                        }
                    });
                });
            } catch (err) {
                console.error(err);
                tbody.innerHTML = `<tr><td colspan="5" class="text-danger text-center py-4">Error loading banners: ${err.message}</td></tr>`;
            }
        }

        window.openSponsoredModal = function() {
            document.getElementById('banner-id').value = '';
            document.getElementById('banner-file').value = '';
            document.getElementById('banner-image-url').value = '';
            document.getElementById('banner-title').value = '';
            document.getElementById('banner-subtitle').value = '';
            document.getElementById('banner-link-url').value = '';
            const modal = new bootstrap.Modal(document.getElementById('sponsoredModal'));
            modal.show();
        };

        function openSponsoredModalWithVendor(vendorId, v) {
            document.getElementById('banner-id').value = '';
            document.getElementById('banner-file').value = '';
            document.getElementById('banner-image-url').value = v.cover_image_url || v.profile_image_url || '';
            document.getElementById('banner-title').value = v.name || '';
            document.getElementById('banner-subtitle').value = `${v.category || 'Vendor'} • ${v.district || 'Sri Lanka'}`;
            document.getElementById('banner-link-url').value = `/vendor-detail?id=${vendorId}`;
            const modal = new bootstrap.Modal(document.getElementById('sponsoredModal'));
            modal.show();
        }

        async function openVendorAnalyticsModal(vendorId, v) {
            document.getElementById('analytics-vendor-name').textContent = `📊 Analytics: ${v.name || 'Vendor'}`;
            document.getElementById('analytics-views').textContent = v.profile_views || 0;
            document.getElementById('analytics-pkg-views').textContent = v.package_views || 0;
            document.getElementById('analytics-inquiries').textContent = v.inquiries_count || 0;
            document.getElementById('analytics-favorites').textContent = v.favorites_count || 0;

            const tbody = document.getElementById('analytics-monthly-tbody');
            tbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted py-3"><div class="spinner-border spinner-border-sm text-primary"></div> Fetching monthly logs...</td></tr>';

            const modal = new bootstrap.Modal(document.getElementById('vendorAnalyticsModal'));
            modal.show();

            try {
                const logsSnap = await getDocs(collection(db, 'vendor_registrations', vendorId, 'analytics_logs'));
                
                const monthStats = {};

                logsSnap.forEach(docSnap => {
                    const data = docSnap.data();
                    if (data.created_at) {
                        const date = data.created_at.toDate();
                        const key = date.toLocaleString('default', { month: 'short', year: 'numeric' });
                        if (!monthStats[key]) {
                            monthStats[key] = { profile_views: 0, package_views: 0, inquiries: 0 };
                        }
                        if (data.type === 'profile_view') monthStats[key].profile_views++;
                        if (data.type === 'package_view') monthStats[key].package_views++;
                        if (data.type === 'inquiry') monthStats[key].inquiries++;
                    }
                });

                tbody.innerHTML = '';
                const months = Object.keys(monthStats);

                if (months.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted py-3">No monthly log entries found yet. Overall totals shown above.</td></tr>';
                } else {
                    months.forEach(m => {
                        const s = monthStats[m];
                        const tr = document.createElement('tr');
                        tr.innerHTML = `
                            <td class="fw-bold">${m}</td>
                            <td><span class="badge bg-primary">${s.profile_views} views</span></td>
                            <td><span class="badge bg-purple" style="background:#6f42c1">${s.package_views} pkgs</span></td>
                            <td><span class="badge bg-success">${s.inquiries} inq</span></td>
                        `;
                        tbody.appendChild(tr);
                    });
                }
            } catch (e) {
                console.error(e);
                tbody.innerHTML = `<tr><td colspan="4" class="text-danger text-center py-3">Error loading breakdown: ${e.message}</td></tr>`;
            }
        }

        document.getElementById('btn-save-banner').addEventListener('click', async () => {
            const btn = document.getElementById('btn-save-banner');
            btn.innerHTML = 'Saving...';
            btn.disabled = true;

            try {
                let imageUrl = document.getElementById('banner-image-url').value.trim();
                const fileInput = document.getElementById('banner-file');

                // If file is selected, upload via upload.php first
                if (fileInput.files.length > 0) {
                    const formData = new FormData();
                    formData.append('image', fileInput.files[0]);
                    const res = await fetch('upload.php', {
                        method: 'POST',
                        body: formData
                    });
                    const data = await res.json();
                    if (data.success && data.url) {
                        imageUrl = data.url;
                    } else {
                        throw new Error(data.message || 'Image upload failed');
                    }
                }

                if (!imageUrl) {
                    alert('Please select an image file or provide an Image URL.');
                    btn.innerHTML = 'Save Banner';
                    btn.disabled = false;
                    return;
                }

                const title = document.getElementById('banner-title').value.trim();
                const subtitle = document.getElementById('banner-subtitle').value.trim();
                const linkUrl = document.getElementById('banner-link-url').value.trim();

                await addDoc(collection(db, 'sponsored_banners'), {
                    image_url: imageUrl,
                    title: title,
                    subtitle: subtitle,
                    link_url: linkUrl,
                    created_at: new Date().toISOString()
                });

                alert('🌟 Sponsored Banner created successfully!');
                const modal = bootstrap.Modal.getInstance(document.getElementById('sponsoredModal'));
                modal.hide();

                if (currentTab === 'sponsored') {
                    loadSponsoredBanners();
                }
            } catch (err) {
                alert('Error saving banner: ' + err.message);
            }

            btn.innerHTML = 'Save Banner';
            btn.disabled = false;
        });

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
