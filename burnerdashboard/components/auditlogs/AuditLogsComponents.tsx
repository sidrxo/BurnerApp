"use client";

import { useState } from "react";
import { useAuditLogs, type AuditLogFilters } from "@/hooks/useAuditLogs";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { AlertCircle, CheckCircle, Info, XCircle, ChevronLeft, ChevronRight, Search, Download } from "lucide-react";

export function AuditLogsPage() {
  const [filters, setFilters] = useState<AuditLogFilters>({});
  const [searchInput, setSearchInput] = useState("");
  const { logs, stats, loading, error, pagination, nextPage, prevPage, refresh } = useAuditLogs(filters);

  const handleSearch = () => {
    setFilters(prev => ({ ...prev, searchQuery: searchInput }));
  };

  const handleFilterChange = (key: keyof AuditLogFilters, value: string | undefined) => {
    setFilters(prev => ({ ...prev, [key]: value }));
  };

  const exportLogs = () => {
    const csv = [
      ['Timestamp', 'Event Type', 'Action', 'User', 'Status', 'Description', 'IP Address'].join(','),
      ...logs.map(log => [
        log.created_at,
        log.event_type,
        log.event_action,
        log.user_email || 'N/A',
        log.status || 'N/A',
        `"${log.action_description}"`,
        log.ip_address || 'N/A'
      ].join(','))
    ].join('\n');

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `audit-logs-${new Date().toISOString()}.csv`;
    a.click();
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Audit Logs</h1>
          <p className="text-muted-foreground mt-1">Track all system activities and transactions</p>
        </div>
        <Button onClick={exportLogs} variant="outline">
          <Download className="w-4 h-4 mr-2" />
          Export CSV
        </Button>
      </div>

      {/* Stats Cards */}
      {stats.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {stats.slice(0, 4).map(stat => (
            <Card key={stat.event_type}>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium capitalize">{stat.event_type}</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stat.total_count}</div>
                <div className="text-xs text-muted-foreground mt-1">
                  {stat.success_count} success · {stat.failure_count} failed
                  {stat.critical_count > 0 && ` · ${stat.critical_count} critical`}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Filters */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Filters</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Select value={filters.eventType || "all"} onValueChange={v => handleFilterChange('eventType', v === 'all' ? undefined : v)}>
              <SelectTrigger>
                <SelectValue placeholder="Event Type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Types</SelectItem>
                <SelectItem value="payment">Payment</SelectItem>
                <SelectItem value="ticket">Ticket</SelectItem>
                <SelectItem value="admin">Admin</SelectItem>
                <SelectItem value="security">Security</SelectItem>
                <SelectItem value="auth">Auth</SelectItem>
              </SelectContent>
            </Select>

            <Select value={filters.severity || "all"} onValueChange={v => handleFilterChange('severity', v === 'all' ? undefined : v)}>
              <SelectTrigger>
                <SelectValue placeholder="Severity" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Severities</SelectItem>
                <SelectItem value="INFO">Info</SelectItem>
                <SelectItem value="WARN">Warning</SelectItem>
                <SelectItem value="ERROR">Error</SelectItem>
                <SelectItem value="CRITICAL">Critical</SelectItem>
              </SelectContent>
            </Select>

            <Select value={filters.status || "all"} onValueChange={v => handleFilterChange('status', v === 'all' ? undefined : v)}>
              <SelectTrigger>
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Statuses</SelectItem>
                <SelectItem value="success">Success</SelectItem>
                <SelectItem value="failure">Failure</SelectItem>
                <SelectItem value="pending">Pending</SelectItem>
              </SelectContent>
            </Select>

            <div className="flex gap-2">
              <Input
                placeholder="Search user, description..."
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
              />
              <Button onClick={handleSearch} variant="secondary">
                <Search className="w-4 h-4" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Logs Table */}
      <Card>
        <CardContent className="p-0">
          {loading ? (
            <div className="p-8 text-center text-muted-foreground">Loading audit logs...</div>
          ) : error ? (
            <div className="p-8 text-center text-red-500">Error: {error}</div>
          ) : logs.length === 0 ? (
            <div className="p-8 text-center text-muted-foreground">No audit logs found</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Timestamp</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Action</TableHead>
                  <TableHead>User</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Description</TableHead>
                  <TableHead>Severity</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {logs.map(log => (
                  <TableRow key={log.id}>
                    <TableCell className="font-mono text-xs">
                      {new Date(log.created_at).toLocaleString()}
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline" className="capitalize">{log.event_type}</Badge>
                    </TableCell>
                    <TableCell className="capitalize">{log.event_action}</TableCell>
                    <TableCell className="text-sm">
                      <div>{log.user_email || 'N/A'}</div>
                      {log.user_role && <div className="text-xs text-muted-foreground">{log.user_role}</div>}
                    </TableCell>
                    <TableCell>
                      {log.status && (
                        <div className="flex items-center gap-1">
                          {log.status === 'success' && <CheckCircle className="w-4 h-4 text-green-500" />}
                          {log.status === 'failure' && <XCircle className="w-4 h-4 text-red-500" />}
                          {log.status === 'pending' && <AlertCircle className="w-4 h-4 text-yellow-500" />}
                          <span className="capitalize text-sm">{log.status}</span>
                        </div>
                      )}
                    </TableCell>
                    <TableCell className="max-w-md truncate" title={log.action_description}>
                      {log.action_description}
                      {log.error_message && (
                        <div className="text-xs text-red-500 mt-1">{log.error_message}</div>
                      )}
                      {log.amount_cents && (
                        <div className="text-xs text-muted-foreground mt-1">
                          ${(log.amount_cents / 100).toFixed(2)}
                        </div>
                      )}
                    </TableCell>
                    <TableCell>
                      <Badge variant={
                        log.severity === 'CRITICAL' ? 'destructive' :
                        log.severity === 'ERROR' ? 'destructive' :
                        log.severity === 'WARN' ? 'default' :
                        'secondary'
                      }>
                        {log.severity}
                      </Badge>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Pagination */}
      {!loading && logs.length > 0 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-muted-foreground">
            Showing {((pagination.page - 1) * pagination.limit) + 1} to {Math.min(pagination.page * pagination.limit, pagination.totalCount)} of {pagination.totalCount} logs
          </p>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={prevPage}
              disabled={pagination.page === 1}
            >
              <ChevronLeft className="w-4 h-4 mr-1" />
              Previous
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={nextPage}
              disabled={pagination.page >= pagination.totalPages}
            >
              Next
              <ChevronRight className="w-4 h-4 ml-1" />
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
