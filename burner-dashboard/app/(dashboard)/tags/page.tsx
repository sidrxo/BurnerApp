"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Palette, ArchiveRestore } from "lucide-react";

import { useTags } from "@/hooks/use-tags";
import { createTag, updateTag, archiveTag } from "@/lib/firestore/events";
import { tagFormSchema, type TagFormValues } from "@/lib/validators";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";

export default function TagsPage() {
  const { tags } = useTags();
  const [editingId, setEditingId] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const form = useForm<TagFormValues>({
    resolver: zodResolver(tagFormSchema),
    defaultValues: { name: "", color: "", description: "" }
  });

  const handleEdit = (id: string) => {
    const tag = tags.find((item) => item.id === id);
    if (!tag) return;
    setEditingId(id);
    form.reset({
      name: tag.name,
      color: tag.color ?? "",
      description: tag.description ?? ""
    });
  };

  const handleReset = () => {
    setEditingId(null);
    form.reset({ name: "", color: "", description: "" });
  };

  const onSubmit = async (values: TagFormValues) => {
    try {
      setIsSubmitting(true);
      if (editingId) {
        await updateTag(editingId, values);
      } else {
        await createTag(values);
      }
      handleReset();
    } catch (error) {
      console.error(error);
      alert((error as Error).message ?? "Failed to persist tag");
    } finally {
      setIsSubmitting(false);
    }
  };

  const toggleArchive = async (id: string, archived: boolean) => {
    try {
      await archiveTag(id, !archived);
    } catch (error) {
      console.error(error);
      alert((error as Error).message ?? "Failed to update tag");
    }
  };

  return (
    <div className="grid gap-6 lg:grid-cols-[2fr_1fr]">
      <Card className="bg-card/40">
        <CardHeader>
          <CardTitle className="text-lg">Event tags</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Description</TableHead>
                <TableHead>Color</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {tags.map((tag) => (
                <TableRow key={tag.id}>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <Badge style={tag.color ? { backgroundColor: tag.color, color: "#0f172a" } : undefined}>{tag.name}</Badge>
                    </div>
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {tag.description ?? "—"}
                  </TableCell>
                  <TableCell className="text-sm">{tag.color ?? "—"}</TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {tag.archived ? "Archived" : "Active"}
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end gap-2">
                      <Button size="icon" variant="ghost" onClick={() => handleEdit(tag.id)}>
                        <Palette className="h-4 w-4" />
                      </Button>
                      <Button size="icon" variant="ghost" onClick={() => toggleArchive(tag.id, !!tag.archived)}>
                        <ArchiveRestore className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
              {tags.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} className="py-8 text-center text-sm text-muted-foreground">
                    No tags defined. Create one to drive in-app filtering and single-tag enforcement.
                  </TableCell>
                </TableRow>
              ) : null}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <Card className="bg-card/40">
        <CardHeader>
          <CardTitle className="text-lg">{editingId ? "Edit tag" : "Create tag"}</CardTitle>
        </CardHeader>
        <CardContent>
          <Form {...form}>
            <form className="space-y-4" onSubmit={form.handleSubmit(onSubmit)}>
              <FormField
                control={form.control}
                name="name"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Name</FormLabel>
                    <FormControl>
                      <Input placeholder="e.g. sunrise" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="color"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Color (hex or CSS)</FormLabel>
                    <FormControl>
                      <Input placeholder="#f97316" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Description</FormLabel>
                    <FormControl>
                      <Textarea rows={3} placeholder="Optional context shown to admins" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <div className="flex items-center justify-end gap-2">
                {editingId ? (
                  <Button type="button" variant="ghost" onClick={handleReset}>
                    Cancel
                  </Button>
                ) : null}
                <Button type="submit" disabled={isSubmitting}>
                  {isSubmitting ? "Saving..." : editingId ? "Update tag" : "Create tag"}
                </Button>
              </div>
            </form>
          </Form>
        </CardContent>
      </Card>
    </div>
  );
}
