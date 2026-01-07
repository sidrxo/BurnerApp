import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

console.log("Delete User Function Initialized");

serve(async (req) => {
    
    // --- 1. ADMIN CLIENT INITIALIZATION (Must use Service Role Key) ---
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
    const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
        console.error("Missing Supabase environment variables.");
        return new Response(JSON.stringify({ error: "Server Configuration Error: Missing secrets." }), { status: 500, headers: { 'Content-Type': 'application/json' }});
    }

    const supabaseAdmin = createClient(
        SUPABASE_URL,
        SERVICE_ROLE_KEY,
        { auth: { persistSession: false } }
    );
    
    // --- 2. REQUEST BODY PARSING AND VALIDATION ---
    let userId: string;

    try {
        const body = await req.json();
        const receivedUserId = body.userId as string; 
        
        console.log("Received userId:", receivedUserId);

        if (!receivedUserId || receivedUserId.length < 36) {
            console.error("Validation Error: userId is missing or invalid.");
            return new Response(JSON.stringify({ error: "Missing or invalid userId in request body." }), { status: 400, headers: { 'Content-Type': 'application/json' }});
        }
        
        // FIX: Convert the UUID to lowercase to satisfy the @supabase/auth-js requirement.
        userId = receivedUserId.toLowerCase();
        
    } catch (e) {
        console.error("Failed to parse JSON body:", e.message);
        return new Response(JSON.stringify({ error: "Invalid JSON format." }), { status: 400, headers: { 'Content-Type': 'application/json' }});
    }
    
    // --- 3. CORE DELETION LOGIC ---
    try {
        console.log(`Attempting to delete data and user for ID: ${userId}`);

        // --- STEP A: DELETE ASSOCIATED USER DATA (PREVENTS DATABASE CONSTRAINT ERRORS) ---

        // Delete Tickets (assuming table name is 'tickets')
        const { error: ticketsError } = await supabaseAdmin
            .from('tickets')
            .delete()
            .eq('userId', userId); // userId is already lowercase
            
        if (ticketsError) throw new Error(`Failed to delete tickets: ${ticketsError.message}`);
        console.log(`Deleted tickets for user ${userId}.`);


        // Delete Bookmarks (assuming table name is 'bookmarks')
        const { error: bookmarksError } = await supabaseAdmin
            .from('bookmarks')
            .delete()
            .eq('userId', userId);

        if (bookmarksError) throw new Error(`Failed to delete bookmarks: ${bookmarksError.message}`);
        console.log(`Deleted bookmarks for user ${userId}.`);


        // Delete User Profile (assuming table name is 'users' and primary key is 'id')
        // This is necessary if the foreign key constraint is not set to ON DELETE CASCADE
        const { error: profileError } = await supabaseAdmin
            .from('users')
            .delete()
            .eq('id', userId);
            
        if (profileError) throw new Error(`Failed to delete user profile: ${profileError.message}`);
        console.log(`Deleted user profile for user ${userId}.`);


        // --- STEP B: DELETE USER FROM AUTH (Final Step) ---
        console.log(`All data cleaned up. Deleting user from auth.users...`);
        const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userId); 

        if (deleteError) {
            console.error("Supabase Admin Delete Failed:", deleteError.message);
            // This happens if the user ID is invalid or not found, but we just checked everything.
            return new Response(JSON.stringify({ error: `Final deletion failed: ${deleteError.message}` }), {
                status: 500,
                headers: { 'Content-Type': 'application/json' },
            });
        }

        console.log(`User ${userId} successfully deleted.`);
        
        // --- 4. SUCCESS RESPONSE ---
        return new Response(JSON.stringify({ message: 'Account successfully deleted.' }), {
            status: 200,
            headers: { 'Content-Type': 'application/json' },
        });

    } catch (e) {
        // Catch any unexpected runtime errors during the deletion process
        console.error("Unexpected runtime exception during deletion:", e.message);
        return new Response(JSON.stringify({ error: `Unexpected server error: ${e.message}` }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        });
    }
});