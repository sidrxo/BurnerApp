"use client";

import { useState, useEffect } from "react";
import { useAuth } from "@/components/useAuth";
import { supabase } from "@/lib/supabase";
import { toast } from "sonner";

export interface Tag {
  id: string;
  name: string;
  name_lowercase?: string;
  description?: string | null;
  color?: string | null;
  order: number;
  active: boolean;
  created_at?: string;
  updated_at?: string;
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
      const { data, error } = await supabase
        .from('tags')
        .select('*')
        .order('order', { ascending: true })
        .order('name', { ascending: true });

      if (error) throw error;

      setTags(data || []);
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

      // Check if tag with this name already exists
      const { data: existing } = await supabase
        .from('tags')
        .select('id')
        .ilike('name', tagData.name.trim())
        .single();

      if (existing) {
        toast.error("A tag with this name already exists");
        return { success: false, error: "Tag already exists" };
      }

      // Get the highest order number
      const { data: maxOrderTag } = await supabase
        .from('tags')
        .select('order')
        .order('order', { ascending: false })
        .limit(1)
        .single();

      const nextOrder = (maxOrderTag?.order ?? -1) + 1;

      // Create the tag
      const { data, error } = await supabase
        .from('tags')
        .insert([{
          name: tagData.name.trim(),
          name_lowercase: tagData.name.trim().toLowerCase(),
          description: tagData.description?.trim() || null,
          color: tagData.color || null,
          order: nextOrder,
          active: true,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        }])
        .select()
        .single();

      if (error) throw error;

      toast.success("Tag created successfully");
      await loadTags();
      return { success: true, tagId: data.id };
    } catch (error: any) {
      console.error("Error creating tag:", error);
      let errorMessage = error.message || "Failed to create tag";
      toast.error(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  const updateTag = async (tagId: string, updates: Partial<Tag>) => {
    try {
      setLoading(true);

      // If name is being updated, check for duplicates
      if (updates.name) {
        const { data: existing } = await supabase
          .from('tags')
          .select('id')
          .ilike('name', updates.name.trim())
          .neq('id', tagId)
          .single();

        if (existing) {
          toast.error("A tag with this name already exists");
          return { success: false, error: "Tag already exists" };
        }
      }

      const updateData: any = {
        updated_at: new Date().toISOString(),
      };

      if (updates.name) {
        updateData.name = updates.name;
        updateData.name_lowercase = updates.name.toLowerCase();
      }
      if (updates.description !== undefined) updateData.description = updates.description;
      if (updates.color !== undefined) updateData.color = updates.color;
      if (typeof updates.active === 'boolean') updateData.active = updates.active;
      if (typeof updates.order === 'number') updateData.order = updates.order;

      const { error } = await supabase
        .from('tags')
        .update(updateData)
        .eq('id', tagId);

      if (error) throw error;

      toast.success("Tag updated successfully");
      await loadTags();
      return { success: true };
    } catch (error: any) {
      console.error("Error updating tag:", error);
      let errorMessage = error.message || "Failed to update tag";
      toast.error(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  const deleteTag = async (tagId: string) => {
    try {
      setLoading(true);

      // Check if tag is being used by any events
      const { data: eventsUsingTag, error: checkError } = await supabase
        .from('events')
        .select('id')
        .contains('tags', [tagId])
        .limit(1);

      if (checkError) throw checkError;

      if (eventsUsingTag && eventsUsingTag.length > 0) {
        toast.error("Cannot delete tag because it's being used by events");
        return { success: false, error: "Tag is in use" };
      }

      const { error } = await supabase
        .from('tags')
        .delete()
        .eq('id', tagId);

      if (error) throw error;

      toast.success("Tag deleted successfully");
      await loadTags();
      return { success: true };
    } catch (error: any) {
      console.error("Error deleting tag:", error);
      let errorMessage = error.message || "Failed to delete tag";
      toast.error(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  const reorderTags = async (tagOrders: Array<{ tagId: string; order: number }>) => {
    try {
      setLoading(true);

      // Update all tags in parallel
      const updatePromises = tagOrders.map(({ tagId, order }) =>
        supabase
          .from('tags')
          .update({ order, updated_at: new Date().toISOString() })
          .eq('id', tagId)
      );

      const results = await Promise.all(updatePromises);

      // Check if any updates failed
      const errors = results.filter(r => r.error);
      if (errors.length > 0) {
        throw new Error("Some tags failed to update");
      }

      toast.success("Tags reordered successfully");
      await loadTags();
      return { success: true };
    } catch (error: any) {
      console.error("Error reordering tags:", error);
      let errorMessage = error.message || "Failed to reorder tags";
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
