"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Switch } from "@/components/ui/switch";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger
} from "@/components/ui/dialog";
import { Trash2, Edit, UserPlus, Shield, Building, Scan, Activity, Power } from "lucide-react";
import { Admin, Venue, CreateAdminData, Scanner, CreateScannerData } from "@/hooks/useAdminManagement";
import { formatDateSafe } from "@/lib/utils";

export function AdminManagementHeader() {
  return (
    <div className="flex items-center space-x-4">
        <div>
        <h1 className="text-3xl font-bold tracking-tight">Admin Management</h1>
      </div>
    </div>
  );
}

interface CreateAdminFormProps {
  venues: Venue[];
  onCreateAdmin: (data: CreateAdminData) => Promise<{ success: boolean; error?: string }>;
}

interface CreateScannerFormProps {
  venues: Venue[];
  currentUserRole: string;
  defaultVenueId?: string | null;
  onCreateScanner: (data: CreateScannerData) => Promise<{ success: boolean; error?: string }>;
  actionLoading: boolean;
}

interface AdminsTableProps {
  admins: Admin[];
  venues: Venue[];
  onDeleteAdmin: (adminId: string) => void;
  onUpdateAdmin: (adminId: string, updates: Partial<Admin>) => void;
}

interface ScannersTableProps {
  scanners: Scanner[];
  venues: Venue[];
  onUpdateScanner: (scannerId: string, updates: Partial<Scanner>) => Promise<any>;
  onDeleteScanner: (scannerId: string) => Promise<any>;
  loading: boolean;
}

// Unified form interface
interface UnifiedCreateFormProps {
  venues: Venue[];
  currentUserRole: string;
  defaultVenueId?: string | null;
  onCreateAdmin: (data: CreateAdminData) => Promise<{ success: boolean; error?: string }>;
  onCreateScanner: (data: CreateScannerData) => Promise<{ success: boolean; error?: string }>;
  actionLoading: boolean;
}

export function UnifiedCreateForm({
  venues,
  currentUserRole,
  defaultVenueId,
  onCreateAdmin,
  onCreateScanner,
  actionLoading
}: UnifiedCreateFormProps) {
  const [userType, setUserType] = useState<'admin' | 'scanner'>('admin');
  const [formData, setFormData] = useState({
    email: '',
    name: '',
    role: 'venueAdmin' as 'venueAdmin' | 'subAdmin' | 'siteAdmin',
    venueId: currentUserRole === 'siteAdmin' ? '' : defaultVenueId || ''
  });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    let result;
    if (userType === 'admin') {
      const adminData: CreateAdminData = {
        email: formData.email,
        name: formData.name,
        role: formData.role,
        venueId: (formData.role === 'venueAdmin' || formData.role === 'subAdmin') ? formData.venueId : undefined
      };
      result = await onCreateAdmin(adminData);
    } else {
      const scannerData: CreateScannerData = {
        email: formData.email,
        name: formData.name,
        venueId: currentUserRole === 'siteAdmin' ? (formData.venueId || null) : defaultVenueId || null
      };
      result = await onCreateScanner(scannerData);
    }

    if (result.success) {
      setFormData({
        email: '',
        name: '',
        role: 'venueAdmin',
        venueId: currentUserRole === 'siteAdmin' ? '' : defaultVenueId || ''
      });
    }

    setLoading(false);
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center space-x-2">
          <UserPlus className="h-5 w-5" />
          <span>Create User</span>
        </CardTitle>
        <CardDescription>
          Add a new administrator or scanner to the system
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* User Type Selector */}
          <div>
            <Label>User Type</Label>
            <div className="grid grid-cols-2 gap-3 mt-2">
              <Button
                type="button"
                variant={userType === 'admin' ? 'default' : 'outline'}
                onClick={() => setUserType('admin')}
                className="w-full"
              >
                <Shield className="h-4 w-4 mr-2" />
                Admin
              </Button>
              <Button
                type="button"
                variant={userType === 'scanner' ? 'default' : 'outline'}
                onClick={() => setUserType('scanner')}
                className="w-full"
              >
                <Scan className="h-4 w-4 mr-2" />
                Scanner
              </Button>
            </div>
          </div>
          <div>
            <Label htmlFor="email">Email</Label>
            <Input
              id="email"
              type="email"
              value={formData.email}
              onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
              required
            />
          </div>

          <div>
            <Label htmlFor="name">Name</Label>
            <Input
              id="name"
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              required
            />
          </div>

          {/* Admin-specific fields */}
          {userType === 'admin' && (
            <div>
              <Label htmlFor="role">Role</Label>
              <Select
                value={formData.role}
                onValueChange={(value: 'venueAdmin' | 'subAdmin' | 'siteAdmin') =>
                  setFormData(prev => ({ ...prev, role: value }))
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {currentUserRole === 'siteAdmin' && (
                    <SelectItem value="siteAdmin">Site Admin</SelectItem>
                  )}
                  <SelectItem value="venueAdmin">Venue Admin</SelectItem>
                  <SelectItem value="subAdmin">Sub Admin</SelectItem>
                </SelectContent>
              </Select>
            </div>
          )}

          {/* Venue selection */}
          {((userType === 'admin' && (formData.role === 'venueAdmin' || formData.role === 'subAdmin')) ||
            (userType === 'scanner' && currentUserRole === 'siteAdmin')) && (
            <div>
              <Label htmlFor="venue">
                {userType === 'admin' ? 'Venue' : 'Assign Venue'}
              </Label>
              <Select
                value={formData.venueId || ''}
                onValueChange={(value) =>
                  setFormData(prev => ({ ...prev, venueId: value }))
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select a venue" />
                </SelectTrigger>
                <SelectContent>
                  {venues.map((venue) => (
                    <SelectItem key={venue.id} value={venue.id}>
                      {venue.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          {/* Info message for non-site admins creating scanners */}
          {userType === 'scanner' && currentUserRole !== 'siteAdmin' && (
            <div className="p-3 bg-muted/50 rounded-md text-sm text-muted-foreground">
              Scanners created from your account are automatically linked to your venue.
            </div>
          )}

          <Button type="submit" disabled={loading || actionLoading} className="w-full">
            {loading || actionLoading ? "Creating..." : `Create ${userType === 'admin' ? 'Admin' : 'Scanner'}`}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

// Keep old forms for backward compatibility but mark as deprecated
export function CreateAdminForm({ venues, onCreateAdmin }: CreateAdminFormProps) {
  const [formData, setFormData] = useState<CreateAdminData>({
    email: '',
    name: '',
    role: 'venueAdmin'
  });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    const result = await onCreateAdmin(formData);

    if (result.success) {
      setFormData({
        email: '',
        name: '',
        role: 'venueAdmin'
      });
    }

    setLoading(false);
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center space-x-2">
          <UserPlus className="h-5 w-5" />
          <span>Create New Admin</span>
        </CardTitle>
        <CardDescription>
          Add a new venue admin, sub-admin, or site administrator
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="email">Email</Label>
            <Input
              id="email"
              type="email"
              value={formData.email}
              onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
              required
            />
          </div>

          <div>
            <Label htmlFor="name">Name</Label>
            <Input
              id="name"
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              required
            />
          </div>

          <div>
            <Label htmlFor="role">Role</Label>
            <Select
              value={formData.role}
              onValueChange={(value: 'venueAdmin' | 'subAdmin' | 'siteAdmin') =>
                setFormData(prev => ({ ...prev, role: value }))
              }
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="siteAdmin">Site Admin</SelectItem>
                <SelectItem value="venueAdmin">Venue Admin</SelectItem>
                <SelectItem value="subAdmin">Sub Admin</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {(formData.role === 'venueAdmin' || formData.role === 'subAdmin') && (
            <div>
              <Label htmlFor="venue">Venue</Label>
              <Select
                value={formData.venueId || ''}
                onValueChange={(value) =>
                  setFormData(prev => ({ ...prev, venueId: value }))
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select a venue" />
                </SelectTrigger>
                <SelectContent>
                  {venues.map((venue) => (
                    <SelectItem key={venue.id} value={venue.id}>
                      {venue.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          <Button type="submit" disabled={loading} className="w-full">
            {loading ? "Creating..." : "Create Admin"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

export function CreateScannerForm({
  venues,
  currentUserRole,
  defaultVenueId,
  onCreateScanner,
  actionLoading
}: CreateScannerFormProps) {
  const initialVenue = currentUserRole === 'siteAdmin' ? '' : defaultVenueId || '';
  const [formData, setFormData] = useState<CreateScannerData>({
    email: '',
    name: '',
    venueId: initialVenue
  });
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);

    const payload: CreateScannerData = {
      email: formData.email.trim(),
      name: formData.name.trim(),
      venueId: currentUserRole === 'siteAdmin' ? (formData.venueId || null) : defaultVenueId || null
    };

    const result = await onCreateScanner(payload);
    if (result.success) {
      setFormData({
        email: '',
        name: '',
        venueId: initialVenue
      });
    }

    setSubmitting(false);
  };

  const disableSubmit = submitting || actionLoading || !formData.email || !formData.name || (currentUserRole === 'siteAdmin' && !formData.venueId);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center space-x-2">
          <Scan className="h-5 w-5" />
          <span>Create Scanner</span>
        </CardTitle>
        <CardDescription>
          Provision QR code scanners for fast check-ins at events
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="scanner-email">Email</Label>
            <Input
              id="scanner-email"
              type="email"
              value={formData.email}
              onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
              required
            />
          </div>

          <div>
            <Label htmlFor="scanner-name">Name</Label>
            <Input
              id="scanner-name"
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              required
            />
          </div>

          {currentUserRole === 'siteAdmin' ? (
            <div>
              <Label htmlFor="scanner-venue">Assign Venue</Label>
              <Select
                value={formData.venueId || ''}
                onValueChange={(value) => setFormData(prev => ({ ...prev, venueId: value }))}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select venue" />
                </SelectTrigger>
                <SelectContent>
                  {venues.map((venue) => (
                    <SelectItem key={venue.id} value={venue.id}>
                      {venue.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          ) : (
            <div className="p-3 bg-muted/50 rounded-md text-sm text-muted-foreground">
              Scanners created from your account are automatically linked to your venue.
            </div>
          )}

          <Button type="submit" disabled={disableSubmit} className="w-full">
            {submitting || actionLoading ? 'Creating...' : 'Create Scanner'}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

export function AdminsTable({ admins, venues, onDeleteAdmin, onUpdateAdmin }: AdminsTableProps) {
  const [editingAdmin, setEditingAdmin] = useState<Admin | null>(null);

  const getVenueName = (venueId?: string) => {
    if (!venueId) return 'N/A';
    const venue = venues.find(v => v.id === venueId);
    return venue?.name || 'Unknown Venue';
  };

  const getRoleBadgeColor = (role: string) => {
    switch (role) {
      case 'siteAdmin':
        return 'bg-red-100 text-red-800 hover:bg-red-200';
      case 'venueAdmin':
        return 'bg-blue-100 text-blue-800 hover:bg-blue-200';
      case 'subAdmin':
        return 'bg-green-100 text-green-800 hover:bg-green-200';
      default:
        return 'bg-gray-100 text-gray-800 hover:bg-gray-200';
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center space-x-2">
          <Building className="h-5 w-5" />
          <span>Administrators</span>
        </CardTitle>
        <CardDescription>
          View and manage all administrators in the system
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Role</TableHead>
                <TableHead>Venue</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Created</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {admins.map((admin) => (
                <TableRow key={admin.id}>
                  <TableCell className="font-medium">{admin.name}</TableCell>
                  <TableCell>{admin.email}</TableCell>
                  <TableCell>
                    <Badge className={getRoleBadgeColor(admin.role)}>
                      {admin.role === 'siteAdmin' ? 'Site Admin' : 
                       admin.role === 'venueAdmin' ? 'Venue Admin' : 'Sub Admin'}
                    </Badge>
                  </TableCell>
                  <TableCell>{getVenueName(admin.venueId)}</TableCell>
                  <TableCell>
                    <Badge variant={admin.active ? "default" : "secondary"}>
                      {admin.active ? "Active" : "Inactive"}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    {admin.createdAt.toLocaleDateString()}
                  </TableCell>
                  <TableCell>
                    <div className="flex space-x-2">
                      <Dialog>
                        <DialogTrigger asChild>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => setEditingAdmin(admin)}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                        </DialogTrigger>
                        <DialogContent>
                          <DialogHeader>
                            <DialogTitle>Edit Administrator</DialogTitle>
                            <DialogDescription>
                              Update administrator information
                            </DialogDescription>
                          </DialogHeader>
                          <EditAdminForm
                            admin={admin}
                            venues={venues}
                            onUpdate={(updates) => {
                              onUpdateAdmin(admin.id, updates);
                              setEditingAdmin(null);
                            }}
                          />
                        </DialogContent>
                      </Dialog>
                      
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => onDeleteAdmin(admin.id)}
                        className="text-red-600 hover:text-red-800"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </CardContent>
    </Card>
  );
}

export function ScannersTable({ scanners, venues, onUpdateScanner, onDeleteScanner, loading }: ScannersTableProps) {
  const getVenueName = (venueId?: string | null) => {
    if (!venueId) return 'All Venues';
    const venue = venues.find(v => v.id === venueId);
    return venue?.name || venueId;
  };

  if (scanners.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <Activity className="h-5 w-5" />
            <span>Active Scanners</span>
          </CardTitle>
          <CardDescription>
            Monitor scanner accounts and their permissions
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="text-sm text-muted-foreground p-6 border border-dashed rounded-md text-center">
            No scanners created yet. Add a scanner to allow staff to validate tickets at the door.
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center space-x-2">
          <Activity className="h-5 w-5" />
          <span>Active Scanners</span>
        </CardTitle>
        <CardDescription>
          Manage who can scan tickets and which venues they can access
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Venue</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Last Active</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {scanners.map((scanner) => (
                <TableRow key={scanner.id}>
                  <TableCell className="font-medium">{scanner.name}</TableCell>
                  <TableCell>{scanner.email}</TableCell>
                  <TableCell>
                    <Badge variant="outline">{getVenueName(scanner.venueId)}</Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <Switch
                        checked={scanner.active !== false}
                        disabled={loading}
                        onCheckedChange={(checked) => onUpdateScanner(scanner.id, { active: checked })}
                      />
                      <span className="text-sm text-muted-foreground">
                        {scanner.active !== false ? 'Enabled' : 'Disabled'}
                      </span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <TooltipProvider delayDuration={150}>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <span className="text-sm text-muted-foreground">
                            {scanner.lastActiveAt ? formatDateSafe(scanner.lastActiveAt) : '—'}
                          </span>
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>Last check-in activity</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      variant="ghost"
                      size="sm"
                      className="text-muted-foreground hover:text-destructive"
                      onClick={() => onDeleteScanner(scanner.id)}
                      disabled={loading}
                    >
                      <Power className="h-4 w-4" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </CardContent>
    </Card>
  );
}

interface EditAdminFormProps {
  admin: Admin;
  venues: Venue[];
  onUpdate: (updates: Partial<Admin>) => void;
}

function EditAdminForm({ admin, venues, onUpdate }: EditAdminFormProps) {
  const [formData, setFormData] = useState({
    name: admin.name,
    email: admin.email,
    role: admin.role,
    venueId: admin.venueId || '',
    active: admin.active
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onUpdate(formData);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <Label htmlFor="edit-name">Name</Label>
        <Input
          id="edit-name"
          value={formData.name}
          onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
          required
        />
      </div>
      
      <div>
        <Label htmlFor="edit-email">Email</Label>
        <Input
          id="edit-email"
          type="email"
          value={formData.email}
          onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
          required
        />
      </div>
      
      <div>
        <Label htmlFor="edit-role">Role</Label>
        <Select 
          value={formData.role} 
          onValueChange={(value: 'venueAdmin' | 'subAdmin' | 'siteAdmin') => 
            setFormData(prev => ({ ...prev, role: value }))
          }
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="siteAdmin">Site Admin</SelectItem>
            <SelectItem value="venueAdmin">Venue Admin</SelectItem>
            <SelectItem value="subAdmin">Sub Admin</SelectItem>
          </SelectContent>
        </Select>
      </div>
      
      {(formData.role === 'venueAdmin' || formData.role === 'subAdmin') && (
        <div>
          <Label htmlFor="edit-venue">Venue</Label>
          <Select 
            value={formData.venueId} 
            onValueChange={(value) => 
              setFormData(prev => ({ ...prev, venueId: value }))
            }
          >
            <SelectTrigger>
              <SelectValue placeholder="Select a venue" />
            </SelectTrigger>
            <SelectContent>
              {venues.map((venue) => (
                <SelectItem key={venue.id} value={venue.id}>
                  {venue.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      )}
      
      <div className="flex items-center space-x-2">
        <input
          type="checkbox"
          id="edit-active"
          checked={formData.active}
          onChange={(e) => setFormData(prev => ({ ...prev, active: e.target.checked }))}
        />
        <Label htmlFor="edit-active">Active</Label>
      </div>
      
      <Button type="submit" className="w-full">
        Update Admin
      </Button>
    </form>
  );
}

export function LoadingSkeleton() {
  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="h-8 bg-gray-200 rounded w-1/3 animate-pulse"></div>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-1">
          <Card>
            <CardHeader>
              <div className="h-6 bg-gray-200 rounded animate-pulse"></div>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="h-10 bg-gray-200 rounded animate-pulse"></div>
                <div className="h-10 bg-gray-200 rounded animate-pulse"></div>
                <div className="h-10 bg-gray-200 rounded animate-pulse"></div>
              </div>
            </CardContent>
          </Card>
        </div>
        <div className="lg:col-span-2">
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
      </div>
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