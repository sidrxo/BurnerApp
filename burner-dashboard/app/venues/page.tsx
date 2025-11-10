"use client";

import RequireAuth from "@/components/require-auth";
import ErrorBoundary from "@/components/ErrorBoundary";
import { useVenuesData } from "@/hooks/useVenuesData";
import {
  AccessDenied,
  VenuesHeader,
  CreateVenueForm,
  EmptyVenuesState,
  VenueGridCard,
  VenueDetailCard
} from "@/components/venues/VenuesComponents";

function VenuesPageContent() {
  const {
    user,
    loading,
    venues,
    actionLoading,
    newVenueName,
    setNewVenueName,
    newVenueAdminEmail,
    setNewVenueAdminEmail,
    newVenueAddress,
    setNewVenueAddress,
    newVenueCity,
    setNewVenueCity,
    newVenueLatitude,
    setNewVenueLatitude,
    newVenueLongitude,
    setNewVenueLongitude,
    newVenueCapacity,
    setNewVenueCapacity,
    newVenueContactEmail,
    setNewVenueContactEmail,
    newVenueWebsite,
    setNewVenueWebsite,
    showCreateVenueDialog,
    setShowCreateVenueDialog,
    handleCreateVenueWithAdmin,
    handleRemoveVenue,
    handleAddAdmin,
    handleRemoveAdmin,
    handleUpdateVenue,
    resetCreateForm
  } = useVenuesData();

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!user) {
    return <AccessDenied />;
  }

  // Site Admin View - Show all venues in a grid
  if (user.role === "siteAdmin") {
    return (
      <div className="space-y-6 max-w-7xl mx-auto">
        <VenuesHeader
          user={user}
          setShowCreateVenueDialog={setShowCreateVenueDialog}
        />

        <CreateVenueForm
          showCreateVenueDialog={showCreateVenueDialog}
          setShowCreateVenueDialog={setShowCreateVenueDialog}
          newVenueName={newVenueName}
          setNewVenueName={setNewVenueName}
          newVenueAdminEmail={newVenueAdminEmail}
          setNewVenueAdminEmail={setNewVenueAdminEmail}
          newVenueAddress={newVenueAddress}
          setNewVenueAddress={setNewVenueAddress}
          newVenueCity={newVenueCity}
          setNewVenueCity={setNewVenueCity}
          newVenueLatitude={newVenueLatitude}
          setNewVenueLatitude={setNewVenueLatitude}
          newVenueLongitude={newVenueLongitude}
          setNewVenueLongitude={setNewVenueLongitude}
          newVenueCapacity={newVenueCapacity}
          setNewVenueCapacity={setNewVenueCapacity}
          newVenueContactEmail={newVenueContactEmail}
          setNewVenueContactEmail={setNewVenueContactEmail}
          newVenueWebsite={newVenueWebsite}
          setNewVenueWebsite={setNewVenueWebsite}
          actionLoading={actionLoading}
          handleCreateVenueWithAdmin={handleCreateVenueWithAdmin}
          resetCreateForm={resetCreateForm}
        />

        {venues.length === 0 ? (
          <EmptyVenuesState 
            user={user}
            setShowCreateVenueDialog={setShowCreateVenueDialog}
          />
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {venues.map((venue) => (
              <VenueGridCard
                key={venue.id}
                venue={venue}
                user={user}
                actionLoading={actionLoading}
                handleRemoveVenue={handleRemoveVenue}
                handleUpdateVenue={handleUpdateVenue}
                handleAddAdmin={handleAddAdmin}
                handleRemoveAdmin={handleRemoveAdmin}
              />
            ))}
          </div>
        )}
      </div>
    );
  }

  // Venue Admin View - Show detailed view of their single venue
  if (user.role === "venueAdmin") {
    const userVenue = venues[0]; // Venue admins only see their venue

    if (!userVenue) {
      return (
        <EmptyVenuesState 
          user={user}
          setShowCreateVenueDialog={setShowCreateVenueDialog}
        />
      );
    }

    return (
      <div className="space-y-6 max-w-4xl mx-auto">
        <VenuesHeader
          user={user}
          setShowCreateVenueDialog={setShowCreateVenueDialog}
        />

        <VenueDetailCard
          venue={userVenue}
          actionLoading={actionLoading}
          handleUpdateVenue={handleUpdateVenue}
          handleAddAdmin={handleAddAdmin}
          handleRemoveAdmin={handleRemoveAdmin}
        />
      </div>
    );
  }

  // Other roles don't have access
  return <AccessDenied />;
}

export default function VenuesPage() {
  return (
    <RequireAuth>
      <VenuesPageContent />
    </RequireAuth>
  );
}