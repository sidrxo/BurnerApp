const {
  verifyAdminPermission,
  validateVenueAccess,
  verifyScannerPermission
} = require('../shared/permissions');

const { HttpsError } = require('firebase-functions/v2/https');

// Mock firebase-admin/auth
jest.mock('firebase-admin/auth', () => ({
  getAuth: jest.fn(() => ({
    getUser: jest.fn()
  }))
}));

const { getAuth } = require('firebase-admin/auth');

describe('Permissions Module', () => {
  let mockAuth;

  beforeEach(() => {
    mockAuth = getAuth();
    jest.clearAllMocks();
  });

  describe('verifyAdminPermission', () => {
    test('should allow siteAdmin for siteAdmin required role', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: { role: 'siteAdmin' }
      });

      const claims = await verifyAdminPermission('user123', 'siteAdmin');
      expect(claims.role).toBe('siteAdmin');
    });

    test('should allow siteAdmin for venueAdmin required role', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: { role: 'siteAdmin' }
      });

      const claims = await verifyAdminPermission('user123', 'venueAdmin');
      expect(claims.role).toBe('siteAdmin');
    });

    test('should allow siteAdmin for subAdmin required role', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: { role: 'siteAdmin' }
      });

      const claims = await verifyAdminPermission('user123', 'subAdmin');
      expect(claims.role).toBe('siteAdmin');
    });

    test('should allow venueAdmin for venueAdmin required role', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: { role: 'venueAdmin' }
      });

      const claims = await verifyAdminPermission('user123', 'venueAdmin');
      expect(claims.role).toBe('venueAdmin');
    });

    test('should allow venueAdmin for subAdmin required role', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: { role: 'venueAdmin' }
      });

      const claims = await verifyAdminPermission('user123', 'subAdmin');
      expect(claims.role).toBe('venueAdmin');
    });

    test('should deny venueAdmin for siteAdmin required role', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: { role: 'venueAdmin' }
      });

      await expect(verifyAdminPermission('user123', 'siteAdmin'))
        .rejects.toThrow(HttpsError);
    });

    test('should deny subAdmin for venueAdmin required role', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: { role: 'subAdmin' }
      });

      await expect(verifyAdminPermission('user123', 'venueAdmin'))
        .rejects.toThrow(HttpsError);
    });

    test('should deny subAdmin for siteAdmin required role', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: { role: 'subAdmin' }
      });

      await expect(verifyAdminPermission('user123', 'siteAdmin'))
        .rejects.toThrow(HttpsError);
    });

    test('should deny user without role', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: {}
      });

      await expect(verifyAdminPermission('user123'))
        .rejects.toThrow(HttpsError);
    });

    test('should deny user with no custom claims', async () => {
      mockAuth.getUser.mockResolvedValue({});

      await expect(verifyAdminPermission('user123'))
        .rejects.toThrow(HttpsError);
    });

    test('should handle auth errors gracefully', async () => {
      mockAuth.getUser.mockRejectedValue(new Error('Auth error'));

      await expect(verifyAdminPermission('user123'))
        .rejects.toThrow(HttpsError);
    });

    test('should return custom claims on success', async () => {
      const customClaims = {
        role: 'siteAdmin',
        venueId: 'venue123',
        someOtherClaim: 'value'
      };

      mockAuth.getUser.mockResolvedValue({ customClaims });

      const result = await verifyAdminPermission('user123', 'siteAdmin');
      expect(result).toEqual(customClaims);
    });

    test('should use siteAdmin as default required role', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: { role: 'siteAdmin' }
      });

      await expect(verifyAdminPermission('user123')).resolves.toBeDefined();

      mockAuth.getUser.mockResolvedValue({
        customClaims: { role: 'venueAdmin' }
      });

      await expect(verifyAdminPermission('user123')).rejects.toThrow();
    });
  });

  describe('validateVenueAccess', () => {
    test('should allow siteAdmin access to any venue', () => {
      const claims = { role: 'siteAdmin' };
      expect(validateVenueAccess(claims, 'venue123')).toBe(true);
      expect(validateVenueAccess(claims, 'venue456')).toBe(true);
      expect(validateVenueAccess(claims, null)).toBe(true);
    });

    test('should allow venueAdmin access to their venue', () => {
      const claims = { role: 'venueAdmin', venueId: 'venue123' };
      expect(validateVenueAccess(claims, 'venue123')).toBe(true);
    });

    test('should deny venueAdmin access to other venues', () => {
      const claims = { role: 'venueAdmin', venueId: 'venue123' };
      expect(validateVenueAccess(claims, 'venue456')).toBe(false);
    });

    test('should allow venueAdmin with null venueId access to all venues', () => {
      const claims = { role: 'venueAdmin', venueId: null };
      expect(validateVenueAccess(claims, 'venue123')).toBe(true);
      expect(validateVenueAccess(claims, 'venue456')).toBe(true);
    });

    test('should allow subAdmin access to their venue', () => {
      const claims = { role: 'subAdmin', venueId: 'venue123' };
      expect(validateVenueAccess(claims, 'venue123')).toBe(true);
    });

    test('should deny subAdmin access to other venues', () => {
      const claims = { role: 'subAdmin', venueId: 'venue123' };
      expect(validateVenueAccess(claims, 'venue456')).toBe(false);
    });

    test('should allow subAdmin with null venueId access to all venues', () => {
      const claims = { role: 'subAdmin', venueId: null };
      expect(validateVenueAccess(claims, 'venue123')).toBe(true);
    });

    test('should allow scanner access to their venue', () => {
      const claims = { role: 'scanner', venueId: 'venue123' };
      expect(validateVenueAccess(claims, 'venue123')).toBe(true);
    });

    test('should deny scanner access to other venues', () => {
      const claims = { role: 'scanner', venueId: 'venue123' };
      expect(validateVenueAccess(claims, 'venue456')).toBe(false);
    });

    test('should allow scanner with null venueId access to all venues', () => {
      const claims = { role: 'scanner', venueId: null };
      expect(validateVenueAccess(claims, 'venue123')).toBe(true);
    });

    test('should deny access for unknown roles', () => {
      const claims = { role: 'unknownRole', venueId: 'venue123' };
      expect(validateVenueAccess(claims, 'venue123')).toBe(false);
    });

    test('should deny access for user role', () => {
      const claims = { role: 'user', venueId: 'venue123' };
      expect(validateVenueAccess(claims, 'venue123')).toBe(false);
    });
  });

  describe('verifyScannerPermission', () => {
    test('should allow active scanner', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: {
          role: 'scanner',
          active: true,
          venueId: 'venue123'
        }
      });

      const claims = await verifyScannerPermission('scanner123');
      expect(claims.role).toBe('scanner');
      expect(claims.active).toBe(true);
    });

    test('should deny inactive scanner', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: {
          role: 'scanner',
          active: false,
          venueId: 'venue123'
        }
      });

      await expect(verifyScannerPermission('scanner123'))
        .rejects.toThrow(HttpsError);
    });

    test('should deny non-scanner role', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: {
          role: 'user',
          active: true
        }
      });

      await expect(verifyScannerPermission('user123'))
        .rejects.toThrow(HttpsError);
    });

    test('should validate venue access when venueId provided', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: {
          role: 'scanner',
          active: true,
          venueId: 'venue123'
        }
      });

      const claims = await verifyScannerPermission('scanner123', 'venue123');
      expect(claims.role).toBe('scanner');
    });

    test('should deny scanner accessing wrong venue', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: {
          role: 'scanner',
          active: true,
          venueId: 'venue123'
        }
      });

      await expect(verifyScannerPermission('scanner123', 'venue456'))
        .rejects.toThrow(HttpsError);
    });

    test('should allow scanner with null venueId to access any venue', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: {
          role: 'scanner',
          active: true,
          venueId: null
        }
      });

      const claims = await verifyScannerPermission('scanner123', 'venue123');
      expect(claims.role).toBe('scanner');
    });

    test('should not validate venue when no venueId provided', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: {
          role: 'scanner',
          active: true,
          venueId: 'venue456'
        }
      });

      const claims = await verifyScannerPermission('scanner123');
      expect(claims.role).toBe('scanner');
    });

    test('should handle auth errors gracefully', async () => {
      mockAuth.getUser.mockRejectedValue(new Error('Auth error'));

      await expect(verifyScannerPermission('scanner123'))
        .rejects.toThrow(HttpsError);
    });

    test('should deny scanner without active flag', async () => {
      mockAuth.getUser.mockResolvedValue({
        customClaims: {
          role: 'scanner',
          venueId: 'venue123'
        }
      });

      await expect(verifyScannerPermission('scanner123'))
        .rejects.toThrow(HttpsError);
    });
  });
});
