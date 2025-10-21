"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { ShieldCheck, Loader2, UserPlus, Power } from "lucide-react";

import { useScanners } from "@/hooks/use-scanners";
import { createScanner, setScannerActive, deleteScanner } from "@/lib/firestore/scanners";
import { scannerFormSchema, type ScannerFormValues } from "@/lib/validators";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { formatDistanceToNow } from "date-fns";

export default function ScannersPage() {
  const { scanners } = useScanners();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const form = useForm<ScannerFormValues>({
    resolver: zodResolver(scannerFormSchema),
    defaultValues: {
      displayName: "",
      email: "",
      venueId: "",
      venueName: "",
      notes: "",
      active: true
    }
  });

  const onSubmit = async (values: ScannerFormValues) => {
    try {
      setIsSubmitting(true);
      await createScanner(values);
      form.reset({
        displayName: "",
        email: "",
        venueId: "",
        venueName: "",
        notes: "",
        active: true
      });
    } catch (error) {
      console.error(error);
      alert((error as Error).message ?? "Failed to create scanner");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggle = async (id: string, active: boolean) => {
    try {
      await setScannerActive(id, !active);
    } catch (error) {
      console.error(error);
      alert((error as Error).message ?? "Unable to update scanner");
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm("Delete this scanner account?")) return;
    try {
      await deleteScanner(id);
    } catch (error) {
      console.error(error);
      alert((error as Error).message ?? "Unable to delete scanner");
    }
  };

  return (
    <div className="grid gap-6 lg:grid-cols-[3fr_2fr]">
      <Card className="bg-card/40">
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-lg">Scanner roster</CardTitle>
          <Badge variant="outline">{scanners.length} accounts</Badge>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Venue</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Last activity</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {scanners.map((scanner) => (
                <TableRow key={scanner.id}>
                  <TableCell>
                    <div className="space-y-1">
                      <p className="font-medium">{scanner.displayName}</p>
                      <p className="text-xs text-muted-foreground">{scanner.email}</p>
                    </div>
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {scanner.venueName || scanner.venueId || scanner.venues?.join(", ") || '—'}
                  </TableCell>
                  <TableCell>
                    <Badge variant={scanner.active ? "secondary" : "outline"}>
                      {scanner.active ? "Active" : "Disabled"}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {scanner.lastSignInAt
                      ? `${formatDistanceToNow(scanner.lastSignInAt, { addSuffix: true })}`
                      : "No scans yet"}
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end gap-2">
                      <Button variant="ghost" size="icon" onClick={() => handleToggle(scanner.id, scanner.active)}>
                        <Power className="h-4 w-4" />
                      </Button>
                      <Button variant="ghost" size="icon" onClick={() => handleDelete(scanner.id)}>
                        <ShieldCheck className="h-4 w-4 text-destructive" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
              {scanners.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} className="py-10 text-center text-sm text-muted-foreground">
                    No scanners have been provisioned. Create one using the form on the right.
                  </TableCell>
                </TableRow>
              ) : null}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <Card className="bg-card/40">
        <CardHeader>
          <CardTitle className="text-lg">Create scanner</CardTitle>
        </CardHeader>
        <CardContent>
          <Form {...form}>
            <form className="space-y-4" onSubmit={form.handleSubmit(onSubmit)}>
              <FormField
                control={form.control}
                name="displayName"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Name</FormLabel>
                    <FormControl>
                      <Input placeholder="Door captain" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="email"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Email</FormLabel>
                    <FormControl>
                      <Input placeholder="scanner@burner.app" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <div className="grid gap-4 md:grid-cols-2">
                <FormField
                  control={form.control}
                  name="venueId"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Venue ID</FormLabel>
                      <FormControl>
                        <Input placeholder="optional" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="venueName"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Venue label</FormLabel>
                      <FormControl>
                        <Input placeholder="Warehouse" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
              <FormField
                control={form.control}
                name="notes"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Notes</FormLabel>
                    <FormControl>
                      <Textarea rows={3} placeholder="Special shifts or instructions" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="active"
                render={({ field }) => (
                  <FormItem>
                    <div className="flex items-center justify-between rounded-lg border border-border/60 bg-muted/10 p-4">
                      <div>
                        <FormLabel className="text-base">Active</FormLabel>
                        <p className="text-xs text-muted-foreground">Allow this scanner to authenticate immediately.</p>
                      </div>
                      <FormControl>
                        <Switch checked={field.value} onCheckedChange={field.onChange} />
                      </FormControl>
                    </div>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <Button type="submit" disabled={isSubmitting} className="w-full">
                {isSubmitting ? (
                  <span className="flex items-center justify-center gap-2">
                    <Loader2 className="h-4 w-4 animate-spin" /> Creating scanner
                  </span>
                ) : (
                  <span className="flex items-center justify-center gap-2">
                    <UserPlus className="h-4 w-4" />
                    Create scanner
                  </span>
                )}
              </Button>
            </form>
          </Form>
        </CardContent>
      </Card>
    </div>
  );
}
