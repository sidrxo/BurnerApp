"use client";

import RequireAuth from "@/components/require-auth";
import { useAuth } from "@/components/useAuth";
import { MigrationPanel } from "@/components/migration/MigrationPanel";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

function MigrationPageContent() {
  const { user } = useAuth();

  if (!user || user.role !== "siteAdmin") {
    return (
      <Card className="max-w-md mx-auto mt-10">
        <CardHeader>
          <CardTitle className="text-center">Access Denied</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-center text-muted-foreground">
            Only site administrators can access database migrations.
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Database Migration</h1>
        <p className="text-muted-foreground mt-2">
          Migrate your Firestore database to the optimized structure
        </p>
      </div>

      <MigrationPanel />
    </div>
  );
}

export default function MigrationPage() {
  return (
    <RequireAuth>
      <MigrationPageContent />
    </RequireAuth>
  );
}