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

    const { action, organizerId, venueId, venueIds } = await req.json()

    // Validate required fields
    if (!action || !organizerId) {
      throw new Error('Missing required fields: action and organizerId are required')
    }

    // Validate action
    const validActions = ['add', 'remove', 'set', 'get']
    if (!validActions.includes(action)) {
      throw new Error('Invalid action. Must be one of: add, remove, set, get')
    }

    // For write operations (add, remove, set), only siteAdmins can perform them
    // For 'get' action, organisers can fetch their own venues
    if (action !== 'get') {
      await verifyAdminPermission(supabase, user.id, 'siteAdmin')
    } else {
      // For 'get' action, allow organisers to fetch their own venues
      const isSiteAdmin = await verifyAdminPermission(supabase, user.id, 'siteAdmin').then(() => true).catch(() => false)
      const isOwnVenues = organizerId === user.id

      if (!isSiteAdmin && !isOwnVenues) {
        throw new Error('You can only fetch your own venue assignments')
      }
    }

    // Verify organizer exists
    const { data: organizer, error: organizerError } = await supabase
      .from('users')
      .select('id, role, email, display_name')
      .eq('id', organizerId)
      .single()

    if (organizerError || !organizer) {
      throw new Error('Organizer not found')
    }

    // For write operations, verify the user has organiser role
    // For 'get', we allow fetching venues for any user (returns empty if not an organiser)
    if (action !== 'get' && organizer.role !== 'organiser') {
      throw new Error('Specified admin is not an organiser')
    }

    // Handle different actions
    if (action === 'add') {
      if (!venueId) {
        throw new Error('venueId is required for add action')
      }

      // Verify venue exists
      const { data: venue, error: venueError } = await supabase
        .from('venues')
        .select('id, name')
        .eq('id', venueId)
        .single()

      if (venueError || !venue) {
        throw new Error('Venue not found')
      }

      // Check if assignment already exists
      const { data: existing } = await supabase
        .from('organizer_venues')
        .select('id')
        .eq('organizer_id', organizerId)
        .eq('venue_id', venueId)
        .single()

      if (existing) {
        return new Response(
          JSON.stringify({
            success: true,
            message: 'Venue already assigned to organizer',
            assignment: existing
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        )
      }

      // Create assignment
      const { data: assignment, error: assignmentError } = await supabase
        .from('organizer_venues')
        .insert({
          organizer_id: organizerId,
          venue_id: venueId,
          created_by: user.id,
          created_at: new Date().toISOString()
        })
        .select()
        .single()

      if (assignmentError) throw assignmentError

      return new Response(
        JSON.stringify({
          success: true,
          message: `Venue "${venue.name}" assigned to organizer "${organizer.display_name}"`,
          assignment: assignment
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    if (action === 'remove') {
      if (!venueId) {
        throw new Error('venueId is required for remove action')
      }

      const { error: deleteError } = await supabase
        .from('organizer_venues')
        .delete()
        .eq('organizer_id', organizerId)
        .eq('venue_id', venueId)

      if (deleteError) throw deleteError

      return new Response(
        JSON.stringify({
          success: true,
          message: 'Venue assignment removed'
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    if (action === 'set') {
      if (!Array.isArray(venueIds)) {
        throw new Error('venueIds array is required for set action')
      }

      // Delete all existing assignments
      await supabase
        .from('organizer_venues')
        .delete()
        .eq('organizer_id', organizerId)

      // Add new assignments
      if (venueIds.length > 0) {
        const assignments = venueIds.map(vId => ({
          organizer_id: organizerId,
          venue_id: vId,
          created_by: user.id,
          created_at: new Date().toISOString()
        }))

        const { error: insertError } = await supabase
          .from('organizer_venues')
          .insert(assignments)

        if (insertError) throw insertError
      }

      return new Response(
        JSON.stringify({
          success: true,
          message: `Organizer venues updated. ${venueIds.length} venue(s) assigned.`
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    if (action === 'get') {
      // Get all venues assigned to this organizer
      const { data: assignments, error: getError } = await supabase
        .from('organizer_venues')
        .select(`
          id,
          venue_id,
          created_at,
          venues:venue_id (
            id,
            name,
            city,
            address,
            active
          )
        `)
        .eq('organizer_id', organizerId)

      if (getError) throw getError

      return new Response(
        JSON.stringify({
          success: true,
          organizer: {
            id: organizer.id,
            name: organizer.display_name,
            email: organizer.email
          },
          venues: assignments || []
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

  } catch (error) {
    console.error('Error managing organizer venues:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
