"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Switch } from "@/components/ui/switch";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger
} from "@/components/ui/alert-dialog";
import { Trash2, Edit, Plus, Tag as TagIcon, GripVertical } from "lucide-react";
import { Tag, CreateTagData } from "@/hooks/useTagManagement";
import { Textarea } from "@/components/ui/textarea";

export function TagManagementHeader() {
  return (
    <div className="flex items-center space-x-4">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Tag Management</h1>
      </div>
    </div>
  );
}

interface CreateTagFormProps {
  onCreateTag: (data: CreateTagData) => Promise<{ success: boolean; error?: string; tagId?: string }>;
  loading: boolean;
}

export function CreateTagForm({ onCreateTag, loading }: CreateTagFormProps) {
  const [formData, setFormData] = useState<CreateTagData>({
    name: '',
    description: '',
    color: ''
  });
  const [open, setOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);

    const result = await onCreateTag(formData);

    if (result.success) {
      setFormData({
        name: '',
        description: '',
        color: ''
      });
      setOpen(false);
    }

    setSubmitting(false);
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button size="lg" className="shadow-md">
          <Plus className="mr-2 h-4 w-4" />
          Create Tag
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Create New Tag</DialogTitle>
          <DialogDescription>
            Add a new tag that will appear in the mobile app
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="name">Tag Name *</Label>
            <Input
              id="name"
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              placeholder="e.g., Techno, House, Jazz"
              required
            />
          </div>

          <div>
            <Label htmlFor="description">Description (Optional)</Label>
            <Textarea
              id="description"
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              placeholder="Brief description of this tag"
              rows={2}
            />
          </div>

          <div>
            <Label htmlFor="color">Color (Optional)</Label>
            <div className="flex space-x-2">
              <Input
                id="color"
                type="color"
                value={formData.color || '#000000'}
                onChange={(e) => setFormData(prev => ({ ...prev, color: e.target.value }))}
                className="w-20 h-10"
              />
              <Input
                type="text"
                value={formData.color || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, color: e.target.value }))}
                placeholder="#000000"
                className="flex-1"
              />
            </div>
          </div>

          <div className="flex space-x-2 pt-4">
            <Button
              type="button"
              variant="outline"
              onClick={() => setOpen(false)}
              className="flex-1"
              disabled={submitting || loading}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={submitting || loading} className="flex-1">
              {submitting ? "Creating..." : "Create Tag"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}

interface TagsTableProps {
  tags: Tag[];
  onUpdateTag: (tagId: string, updates: Partial<Tag>) => Promise<any>;
  onDeleteTag: (tagId: string) => Promise<any>;
  loading: boolean;
}

export function TagsTable({ tags, onUpdateTag, onDeleteTag, loading }: TagsTableProps) {
  const [editingTag, setEditingTag] = useState<Tag | null>(null);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center space-x-2">
          <TagIcon className="h-5 w-5" />
          <span>All Tags</span>
        </CardTitle>
        <CardDescription>
          View and manage all event tags. Tags are displayed in the mobile app in this order.
        </CardDescription>
      </CardHeader>
      <CardContent>
        {tags.length === 0 ? (
          <div className="text-sm text-muted-foreground p-6 border border-dashed rounded-md text-center">
            No tags created yet. Create your first tag to get started.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-12"></TableHead>
                  <TableHead>Name</TableHead>
                  <TableHead>Description</TableHead>
                  <TableHead>Color</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Order</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {tags.map((tag) => (
                  <TableRow key={tag.id}>
                    <TableCell>
                      <GripVertical className="h-4 w-4 text-muted-foreground" />
                    </TableCell>
                    <TableCell className="font-medium">{tag.name}</TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {tag.description || '—'}
                    </TableCell>
                    <TableCell>
                      {tag.color ? (
                        <div className="flex items-center space-x-2">
                          <div
                            className="w-6 h-6 rounded border"
                            style={{ backgroundColor: tag.color }}
                          />
                          <span className="text-xs text-muted-foreground">{tag.color}</span>
                        </div>
                      ) : (
                        <span className="text-muted-foreground">—</span>
                      )}
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <Switch
                          checked={tag.active}
                          disabled={loading}
                          onCheckedChange={(checked) => onUpdateTag(tag.id, { active: checked })}
                        />
                        <span className="text-sm text-muted-foreground">
                          {tag.active ? 'Active' : 'Inactive'}
                        </span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline">{tag.order}</Badge>
                    </TableCell>
                    <TableCell>
                      <div className="flex space-x-2">
                        <Dialog>
                          <DialogTrigger asChild>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => setEditingTag(tag)}
                            >
                              <Edit className="h-4 w-4" />
                            </Button>
                          </DialogTrigger>
                          <DialogContent>
                            <DialogHeader>
                              <DialogTitle>Edit Tag</DialogTitle>
                              <DialogDescription>
                                Update tag information
                              </DialogDescription>
                            </DialogHeader>
                            <EditTagForm
                              tag={tag}
                              onUpdate={(updates) => {
                                onUpdateTag(tag.id, updates);
                                setEditingTag(null);
                              }}
                              loading={loading}
                            />
                          </DialogContent>
                        </Dialog>

                        <AlertDialog>
                          <AlertDialogTrigger asChild>
                            <Button
                              variant="outline"
                              size="sm"
                              className="text-red-600 hover:text-red-800"
                              disabled={loading}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </AlertDialogTrigger>
                          <AlertDialogContent>
                            <AlertDialogHeader>
                              <AlertDialogTitle>Delete Tag</AlertDialogTitle>
                              <AlertDialogDescription>
                                Are you sure you want to delete "{tag.name}"? This action cannot be undone.
                                If this tag is used in any events, the deletion will fail.
                              </AlertDialogDescription>
                            </AlertDialogHeader>
                            <AlertDialogFooter>
                              <AlertDialogCancel>Cancel</AlertDialogCancel>
                              <AlertDialogAction
                                onClick={() => onDeleteTag(tag.id)}
                                className="bg-red-600 hover:bg-red-700"
                              >
                                Delete
                              </AlertDialogAction>
                            </AlertDialogFooter>
                          </AlertDialogContent>
                        </AlertDialog>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

interface EditTagFormProps {
  tag: Tag;
  onUpdate: (updates: Partial<Tag>) => void;
  loading: boolean;
}

function EditTagForm({ tag, onUpdate, loading }: EditTagFormProps) {
  const [formData, setFormData] = useState({
    name: tag.name,
    description: tag.description || '',
    color: tag.color || '',
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onUpdate(formData);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <Label htmlFor="edit-name">Tag Name</Label>
        <Input
          id="edit-name"
          value={formData.name}
          onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
          required
        />
      </div>

      <div>
        <Label htmlFor="edit-description">Description</Label>
        <Textarea
          id="edit-description"
          value={formData.description}
          onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
          rows={2}
        />
      </div>

      <div>
        <Label htmlFor="edit-color">Color</Label>
        <div className="flex space-x-2">
          <Input
            id="edit-color"
            type="color"
            value={formData.color || '#000000'}
            onChange={(e) => setFormData(prev => ({ ...prev, color: e.target.value }))}
            className="w-20 h-10"
          />
          <Input
            type="text"
            value={formData.color || ''}
            onChange={(e) => setFormData(prev => ({ ...prev, color: e.target.value }))}
            placeholder="#000000"
            className="flex-1"
          />
        </div>
      </div>

      <Button type="submit" disabled={loading} className="w-full">
        {loading ? "Updating..." : "Update Tag"}
      </Button>
    </form>
  );
}

export function LoadingSkeleton() {
  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="h-8 bg-gray-200 rounded w-1/3 animate-pulse"></div>
      <Card>
        <CardHeader>
          <div className="h-6 bg-gray-200 rounded animate-pulse"></div>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="h-12 bg-gray-200 rounded animate-pulse"></div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

export function AccessDenied() {
  return (
    <div className="flex items-center justify-center min-h-[400px]">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-red-600">Access Denied</CardTitle>
          <CardDescription>
            You don't have permission to access this page. Site administrator privileges are required.
          </CardDescription>
        </CardHeader>
      </Card>
    </div>
  );
}
