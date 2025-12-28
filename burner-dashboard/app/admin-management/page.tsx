"use client";

import RequireAuth from "@/components/require-auth";
import { useAdminManagement } from "@/hooks/useAdminManagement";
import {
  AdminManagementHeader,
  UnifiedCreateForm,
  AdminsTable,
  ScannersTable,
  OrganiserVenueManagement,
  LoadingSkeleton,
  AccessDenied
} from "@/components/adminmanagement/AdminManagementComponents";

function AdminManagementPageContent() {
  const {
    user,
    authLoading,
    loading,
    admins,
    venues,
    scanners,
    createAdmin,
    deleteAdmin,
    updateAdmin,
    createScanner,
    updateScanner,
    deleteScanner,
    manageOrganizerVenues
  } = useAdminManagement();

  // Show loading state while auth is loading
  if (authLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  // Allow siteAdmin, venueAdmin, and subAdmin to access
  if (!user || !['siteAdmin', 'venueAdmin', 'subAdmin'].includes(user.role)) {
    return <AccessDenied />;
  }

  if (loading) {
    return <LoadingSkeleton />;
  }

  // Filter data based on user role
  const filteredAdmins = user.role === 'siteAdmin'
    ? admins
    : admins.filter(admin => admin.venueId === user.venueId);

  const filteredScanners = user.role === 'siteAdmin'
    ? scanners
    : scanners.filter(scanner => scanner.venueId === user.venueId);

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <AdminManagementHeader />

      {/* Vertical Stack Layout */}
      <div className="space-y-6">
        {/* Unified Create Form */}
        <UnifiedCreateForm
          venues={venues}
          currentUserRole={user.role}
          defaultVenueId={user.venueId}
          onCreateAdmin={createAdmin}
          onCreateScanner={createScanner}
          actionLoading={loading}
        />

        {/* Administrators Table */}
        {(user.role === 'siteAdmin' || user.role === 'venueAdmin') && (
          <AdminsTable
            admins={filteredAdmins}
            venues={venues}
            onDeleteAdmin={deleteAdmin}
            onUpdateAdmin={updateAdmin}
          />
        )}

        {/* Organiser Venue Management - Only for Site Admins */}
        {user.role === 'siteAdmin' && (
          <OrganiserVenueManagement
            admins={admins}
            venues={venues}
            onManageVenues={manageOrganizerVenues}
            loading={loading}
          />
        )}

        {/* Scanners Table */}
        <ScannersTable
          scanners={filteredScanners}
          venues={venues}
          onUpdateScanner={updateScanner}
          onDeleteScanner={deleteScanner}
          loading={loading}
        />
      </div>
    </div>
  );
}

export default function AdminManagementPage() {
  return (
    <RequireAuth>
      <AdminManagementPageContent />
    </RequireAuth>
  );
}