"use client";

import { useState, useEffect } from "react";
import { useAuth } from "@/components/useAuth";
import {
  collection,
  getDocs,
  query,
  orderBy
} from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { db, functions } from "@/lib/firebase";
import { toast } from "sonner";

export interface Tag {
  id: string;
  name: string;
  nameLowercase?: string;
  description?: string | null;
  color?: string | null;
  order: number;
  active: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface CreateTagData {
  name: string;
  description?: string;
  color?: string;
}

export function useTagManagement() {
  const { user, loading: authLoading } = useAuth();
  const [tags, setTags] = useState<Tag[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!authLoading && user && user.role === "siteAdmin") {
      loadTags();
    } else if (!authLoading && user && user.role !== "siteAdmin") {
      setLoading(false);
    }
  }, [user, authLoading]);

  const loadTags = async () => {
    setLoading(true);
    try {
      const tagsSnapshot = await getDocs(
        query(collection(db, "tags"), orderBy("order", "asc"), orderBy("name", "asc"))
      );

      const tagsData = tagsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate(),
        updatedAt: doc.data().updatedAt?.toDate(),
      } as Tag));

      setTags(tagsData);
    } catch (error) {
      console.error("Error loading tags:", error);
      toast.error("Failed to load tags");
    } finally {
      setLoading(false);
    }
  };

  const createTag = async (tagData: CreateTagData) => {
    try {
      setLoading(true);

      const createTagFunction = httpsCallable(functions, 'createTag');
      const result = await createTagFunction({
        name: tagData.name.trim(),
        description: tagData.description?.trim() || null,
        color: tagData.color || null,
      });

      const response = result.data as any;

      if (response.success) {
        toast.success(response.message);
        await loadTags();
        return { success: true, tagId: response.tagId };
      } else {
        throw new Error(response.message || "Failed to create tag");
      }
    } catch (error: any) {
      console.error("Error creating tag:", error);

      let errorMessage = "Failed to create tag";

      if (error.code === 'functions/permission-denied') {
        errorMessage = "You don't have permission to create tags";
      } else if (error.code === 'functions/already-exists') {
        errorMessage = "A tag with this name already exists";
      } else if (error.message) {
        errorMessage = error.message;
      }

      toast.error(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  const updateTag = async (tagId: string, updates: Partial<Tag>) => {
    try {
      setLoading(true);

      const updateTagFunction = httpsCallable(functions, 'updateTag');
      const result = await updateTagFunction({
        tagId: tagId,
        updates: {
          ...(updates.name && { name: updates.name }),
          ...(updates.description !== undefined && { description: updates.description }),
          ...(updates.color !== undefined && { color: updates.color }),
          ...(typeof updates.active === 'boolean' && { active: updates.active }),
          ...(typeof updates.order === 'number' && { order: updates.order }),
        }
      });

      const response = result.data as any;

      if (response.success) {
        toast.success(response.message);
        await loadTags();
        return { success: true };
      } else {
        throw new Error(response.message || "Failed to update tag");
      }
    } catch (error: any) {
      console.error("Error updating tag:", error);

      let errorMessage = "Failed to update tag";

      if (error.code === 'functions/permission-denied') {
        errorMessage = "You don't have permission to update this tag";
      } else if (error.code === 'functions/not-found') {
        errorMessage = "Tag not found";
      } else if (error.code === 'functions/already-exists') {
        errorMessage = "A tag with this name already exists";
      } else if (error.message) {
        errorMessage = error.message;
      }

      toast.error(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  const deleteTag = async (tagId: string) => {
    try {
      setLoading(true);

      const deleteTagFunction = httpsCallable(functions, 'deleteTag');
      const result = await deleteTagFunction({
        tagId: tagId
      });

      const response = result.data as any;

      if (response.success) {
        toast.success(response.message);
        await loadTags();
        return { success: true };
      } else {
        throw new Error(response.message || "Failed to delete tag");
      }
    } catch (error: any) {
      console.error("Error deleting tag:", error);

      let errorMessage = "Failed to delete tag";

      if (error.code === 'functions/permission-denied') {
        errorMessage = "You don't have permission to delete this tag";
      } else if (error.code === 'functions/not-found') {
        errorMessage = "Tag not found";
      } else if (error.code === 'functions/failed-precondition') {
        errorMessage = error.message || "Cannot delete tag because it's in use";
      } else if (error.message) {
        errorMessage = error.message;
      }

      toast.error(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  const reorderTags = async (tagOrders: Array<{ tagId: string; order: number }>) => {
    try {
      setLoading(true);

      const reorderTagsFunction = httpsCallable(functions, 'reorderTags');
      const result = await reorderTagsFunction({
        tagOrders
      });

      const response = result.data as any;

      if (response.success) {
        toast.success(response.message);
        await loadTags();
        return { success: true };
      } else {
        throw new Error(response.message || "Failed to reorder tags");
      }
    } catch (error: any) {
      console.error("Error reordering tags:", error);

      let errorMessage = "Failed to reorder tags";

      if (error.code === 'functions/permission-denied') {
        errorMessage = "You don't have permission to reorder tags";
      } else if (error.message) {
        errorMessage = error.message;
      }

      toast.error(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  return {
    user,
    authLoading,
    loading,
    tags,
    createTag,
    updateTag,
    deleteTag,
    reorderTags,
    loadTags,
  };
}
