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

    // Check if user already exists in database or auth
    const { data: existingUser } = await supabase
      .from('users')
      .select('id, email')
      .eq('email', email.trim())
      .single()

    if (existingUser) {
      throw new Error('User with this email already exists')
    }

    // Check if auth user exists (in case of orphaned auth account)
    const { data: existingAuthUser } = await supabase.auth.admin.listUsers()
    const authUserExists = existingAuthUser?.users?.find(u => u.email === email.trim())

    let authData

    if (authUserExists) {
      // Delete orphaned auth user and recreate
      await supabase.auth.admin.deleteUser(authUserExists.id)
    }

    // Create Supabase auth user
    const { data: newAuthData, error: authError } = await supabase.auth.admin.createUser({
      email: email.trim(),
      password: password,
      email_confirm: true, // Auto-confirm email
      user_metadata: {
        display_name: display_name.trim(),
        role: role,
      }
    })

    if (authError) throw new Error(`Failed to create auth user: ${authError.message}`)
    if (!newAuthData.user) throw new Error('Failed to create auth user')

    authData = newAuthData

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
      throw new Error(`Failed to create user record: ${adminError.message || JSON.stringify(adminError)}`)
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
    const errorMessage = error instanceof Error ? error.message : String(error)
    return new Response(
      JSON.stringify({
        error: errorMessage,
        success: false
      }),
      {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
