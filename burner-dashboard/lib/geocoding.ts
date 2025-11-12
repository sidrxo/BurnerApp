/**
 * Geocoding utilities for converting addresses to coordinates
 */

export interface Coordinates {
  latitude: number;
  longitude: number;
}

export interface GeocodingResult {
  coordinates: Coordinates;
  formattedAddress: string;
  city?: string;
}

/**
 * Parse coordinates from various formats:
 * - "51.5074, -0.1278"
 * - "51.5074,-0.1278"
 * - "51.5074 -0.1278"
 */
export function parseCoordinates(input: string): Coordinates | null {
  const trimmed = input.trim();

  // Try to match lat,long pattern (with comma, space, or both)
  const match = trimmed.match(/^(-?\d+\.?\d*)[,\s]+(-?\d+\.?\d*)$/);

  if (match) {
    const latitude = parseFloat(match[1]);
    const longitude = parseFloat(match[2]);

    if (isValidLatitude(latitude) && isValidLongitude(longitude)) {
      return { latitude, longitude };
    }
  }

  return null;
}

/**
 * Validate latitude (-90 to 90)
 */
export function isValidLatitude(lat: number): boolean {
  return !isNaN(lat) && lat >= -90 && lat <= 90;
}

/**
 * Validate longitude (-180 to 180)
 */
export function isValidLongitude(lng: number): boolean {
  return !isNaN(lng) && lng >= -180 && lng <= 180;
}

/**
 * Geocode an address using OpenStreetMap Nominatim API (free, no API key required)
 * Rate limit: 1 request per second
 */
export async function geocodeAddress(address: string): Promise<GeocodingResult | null> {
  if (!address.trim()) {
    return null;
  }

  try {
    const url = new URL('https://nominatim.openstreetmap.org/search');
    url.searchParams.set('q', address);
    url.searchParams.set('format', 'json');
    url.searchParams.set('limit', '1');
    url.searchParams.set('addressdetails', '1');

    const response = await fetch(url.toString(), {
      headers: {
        'User-Agent': 'BurnerApp Dashboard', // Nominatim requires a User-Agent
      },
    });

    if (!response.ok) {
      throw new Error('Geocoding request failed');
    }

    const data = await response.json();

    if (!data || data.length === 0) {
      return null;
    }

    const result = data[0];
    const latitude = parseFloat(result.lat);
    const longitude = parseFloat(result.lon);

    if (!isValidLatitude(latitude) || !isValidLongitude(longitude)) {
      return null;
    }

    return {
      coordinates: { latitude, longitude },
      formattedAddress: result.display_name,
      city: result.address?.city || result.address?.town || result.address?.village,
    };
  } catch (error) {
    console.error('Geocoding error:', error);
    return null;
  }
}

/**
 * Format coordinates for display
 */
export function formatCoordinates(lat: number, lng: number): string {
  return `${lat.toFixed(6)}, ${lng.toFixed(6)}`;
}
