"use client";

import RequireAuth from "@/components/require-auth";
import { useTagManagement } from "@/hooks/useTagManagement";
import {
  TagManagementHeader,
  CreateTagForm,
  TagsTable,
  LoadingSkeleton,
  AccessDenied
} from "@/components/tags/TagManagementComponents";

function TagManagementPageContent() {
  const {
    user,
    authLoading,
    loading,
    tags,
    createTag,
    updateTag,
    deleteTag,
  } = useTagManagement();

  // Show loading state while auth is loading
  if (authLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  // Only allow siteAdmin to access
  if (!user || user.role !== "siteAdmin") {
    return <AccessDenied />;
  }

  if (loading) {
    return <LoadingSkeleton />;
  }

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex justify-between items-center">
        <TagManagementHeader />
        <CreateTagForm onCreateTag={createTag} loading={loading} />
      </div>

      <TagsTable
        tags={tags}
        onUpdateTag={updateTag}
        onDeleteTag={deleteTag}
        loading={loading}
      />
    </div>
  );
}

export default function TagManagementPage() {
  return (
    <RequireAuth>
      <TagManagementPageContent />
    </RequireAuth>
  );
}
