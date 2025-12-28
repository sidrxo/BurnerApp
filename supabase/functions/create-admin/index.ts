import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

import { corsHeaders } from "../_shared/cors.ts"
import { createAdminClient } from "../_shared/supabase.ts"
import { verifyAdminPermission } from "../_shared/permissions.ts"

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabase = createAdminClient()
    const authHeader = req.headers.get('Authorization')
    const { data: { user } } = await supabase.auth.getUser(authHeader?.replace('Bearer ', '') ?? '')
    if (!user) throw new Error('Unauthenticated')

    // Only siteAdmins can create other admins
    await verifyAdminPermission(supabase, user.id, 'siteAdmin')

    const { email, password, display_name, role, venueId } = await req.json()

    // Validate required fields
    if (!email || !password || !display_name || !role) {
      throw new Error('Missing required fields: email, password, display_name, and role are required')
    }

    // Validate role
    const validRoles = ['siteAdmin', 'venueAdmin', 'subAdmin', 'scanner', 'organiser']
    if (!validRoles.includes(role)) {
      throw new Error('Invalid role. Must be one of: siteAdmin, venueAdmin, subAdmin, scanner, organiser')
    }

    // Validate password strength (minimum 6 characters)
    if (password.length < 6) {
      throw new Error('Password must be at least 6 characters long')
    }

    // Check if admin already exists in database
    const { data: existingAdmin } = await supabase
      .from('users')
      .select('id')
      .eq('email', email.trim())
      .single()

    if (existingAdmin) {
      throw new Error('Admin with this email already exists')
    }

    // Create Supabase auth user
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: email.trim(),
      password: password,
      email_confirm: true, // Auto-confirm email
      user_metadata: {
        display_name: display_name.trim(),
        role: role,
      }
    })

    if (authError) throw authError
    if (!authData.user) throw new Error('Failed to create auth user')

    // Create admin entry in database
    const { data: adminData, error: adminError } = await supabase
      .from('users')
      .insert({
        id: authData.user.id,
        email: email.trim(),
        display_name: display_name.trim(),
        role: role,
        venue_id: venueId || null,
        active: true,
        created_at: new Date().toISOString(),
      })
      .select()
      .single()

    if (adminError) {
      // Rollback: Delete the auth user if database insert fails
      await supabase.auth.admin.deleteUser(authData.user.id)
      throw adminError
    }

    return new Response(
      JSON.stringify({
        success: true,
        adminId: adminData.id,
        message: 'Admin created successfully'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  } catch (error) {
    console.error('Error creating admin:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
