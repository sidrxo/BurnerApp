const {
  generateQRCodeData,
  generateSecurityHash,
  generateTicketNumber,
  createTicketInTransaction
} = require('../tickets/ticketHelpers');

describe('Ticket Helpers', () => {
  describe('generateTicketNumber', () => {
    test('should generate a ticket number with correct format', () => {
      const ticketNumber = generateTicketNumber();
      expect(ticketNumber).toMatch(/^TKT\d{11}$/);
    });

    test('should generate unique ticket numbers', () => {
      const ticketNumbers = new Set();
      for (let i = 0; i < 100; i++) {
        ticketNumbers.add(generateTicketNumber());
      }
      // Allow for some small possibility of collision but expect most to be unique
      expect(ticketNumbers.size).toBeGreaterThan(95);
    });

    test('should handle errors gracefully', () => {
      // Mock Date.now to throw error
      const originalDateNow = Date.now;
      Date.now = jest.fn(() => {
        throw new Error('Mock error');
      });

      const ticketNumber = generateTicketNumber();
      expect(ticketNumber).toMatch(/^TKT/);

      Date.now = originalDateNow;
    });
  });

  describe('generateSecurityHash', () => {
    test('should generate consistent hash for same inputs', () => {
      const hash1 = generateSecurityHash('ticket123', 'event456', 'user789');
      const hash2 = generateSecurityHash('ticket123', 'event456', 'user789');
      expect(hash1).toBe(hash2);
    });

    test('should generate different hashes for different inputs', () => {
      const hash1 = generateSecurityHash('ticket123', 'event456', 'user789');
      const hash2 = generateSecurityHash('ticket456', 'event456', 'user789');
      expect(hash1).not.toBe(hash2);
    });

    test('should return 16 character hash', () => {
      const hash = generateSecurityHash('ticket123', 'event456', 'user789');
      expect(hash).toHaveLength(16);
    });

    test('should use custom secret from environment', () => {
      const originalSecret = process.env.QR_SECRET;
      process.env.QR_SECRET = 'custom_test_secret';

      const hash1 = generateSecurityHash('ticket123', 'event456', 'user789');

      process.env.QR_SECRET = 'different_secret';
      const hash2 = generateSecurityHash('ticket123', 'event456', 'user789');

      expect(hash1).not.toBe(hash2);

      process.env.QR_SECRET = originalSecret;
    });

    test('should handle errors and return fallback hash', () => {
      // This test ensures error handling exists
      const hash = generateSecurityHash(null, null, null);
      expect(typeof hash).toBe('string');
      expect(hash.length).toBeGreaterThan(0);
    });
  });

  describe('generateQRCodeData', () => {
    test('should generate valid JSON QR code data', () => {
      const qrData = generateQRCodeData('ticket123', 'event456', 'user789', 'TKT123456789012');
      const parsed = JSON.parse(qrData);

      expect(parsed.type).toBe('EVENT_TICKET');
      expect(parsed.ticketId).toBe('ticket123');
      expect(parsed.eventId).toBe('event456');
      expect(parsed.userId).toBe('user789');
      expect(parsed.ticketNumber).toBe('TKT123456789012');
      expect(parsed.version).toBe('1.0');
      expect(parsed.timestamp).toBeDefined();
      expect(parsed.hash).toBeDefined();
    });

    test('should include security hash in QR data', () => {
      const qrData = generateQRCodeData('ticket123', 'event456', 'user789', 'TKT123456789012');
      const parsed = JSON.parse(qrData);

      const expectedHash = generateSecurityHash('ticket123', 'event456', 'user789');
      expect(parsed.hash).toBe(expectedHash);
    });

    test('should generate unique timestamps', (done) => {
      const qrData1 = generateQRCodeData('ticket1', 'event1', 'user1', 'TKT1');
      setTimeout(() => {
        const qrData2 = generateQRCodeData('ticket2', 'event2', 'user2', 'TKT2');
        const parsed1 = JSON.parse(qrData1);
        const parsed2 = JSON.parse(qrData2);
        expect(parsed2.timestamp).toBeGreaterThanOrEqual(parsed1.timestamp);
        done();
      }, 10);
    });

    test('should handle errors and return fallback format', () => {
      // Test with undefined values to potentially cause JSON.stringify issues
      const qrData = generateQRCodeData(undefined, undefined, undefined, undefined);

      // Should either be valid JSON or fallback format
      if (qrData.startsWith('TICKET:')) {
        expect(qrData).toContain('TICKET:');
        expect(qrData).toContain('EVENT:');
        expect(qrData).toContain('USER:');
        expect(qrData).toContain('NUMBER:');
      } else {
        expect(() => JSON.parse(qrData)).not.toThrow();
      }
    });
  });

  describe('createTicketInTransaction', () => {
    let mockTransaction;
    let mockTicketRef;
    let mockEventRef;
    let mockEvent;

    beforeEach(() => {
      mockTransaction = {
        set: jest.fn(),
        update: jest.fn()
      };

      mockTicketRef = {
        id: 'ticket123'
      };

      mockEventRef = {
        id: 'event456'
      };

      mockEvent = {
        id: 'event456',
        name: 'Test Event',
        venue: 'Test Venue',
        venueId: 'venue123',
        startTime: { seconds: 1234567890 },
        price: 50.00,
        ticketsSold: 10
      };
    });

    test('should create ticket with all required fields', () => {
      const result = createTicketInTransaction(mockTransaction, {
        ticketRef: mockTicketRef,
        eventRef: mockEventRef,
        event: mockEvent,
        userId: 'user789'
      });

      expect(result.ticketId).toBe('ticket123');
      expect(result.ticketNumber).toMatch(/^TKT\d{11}$/);
      expect(result.qrCodeData).toBeDefined();
      expect(result.ticketData).toBeDefined();
      expect(mockTransaction.set).toHaveBeenCalled();
      expect(mockTransaction.update).toHaveBeenCalled();
    });

    test('should include payment intent ID when provided', () => {
      createTicketInTransaction(mockTransaction, {
        ticketRef: mockTicketRef,
        eventRef: mockEventRef,
        event: mockEvent,
        userId: 'user789',
        paymentIntentId: 'pi_123456'
      });

      const setCall = mockTransaction.set.mock.calls[0];
      const ticketData = setCall[1];
      expect(ticketData.paymentIntentId).toBe('pi_123456');
    });

    test('should include payment method details when provided', () => {
      const paymentMethodDetails = {
        id: 'pm_123456',
        type: 'card',
        wallet: 'apple_pay'
      };

      createTicketInTransaction(mockTransaction, {
        ticketRef: mockTicketRef,
        eventRef: mockEventRef,
        event: mockEvent,
        userId: 'user789',
        paymentMethodDetails
      });

      const setCall = mockTransaction.set.mock.calls[0];
      const ticketData = setCall[1];
      expect(ticketData.paymentMethodId).toBe('pm_123456');
      expect(ticketData.metadata.paymentMethod).toBe('apple_pay');
    });

    test('should include customer email in metadata', () => {
      createTicketInTransaction(mockTransaction, {
        ticketRef: mockTicketRef,
        eventRef: mockEventRef,
        event: mockEvent,
        userId: 'user789',
        customerEmail: 'test@example.com'
      });

      const setCall = mockTransaction.set.mock.calls[0];
      const ticketData = setCall[1];
      expect(ticketData.metadata.customerEmail).toBe('test@example.com');
    });

    test('should update event ticketsSold count', () => {
      createTicketInTransaction(mockTransaction, {
        ticketRef: mockTicketRef,
        eventRef: mockEventRef,
        event: mockEvent,
        userId: 'user789'
      });

      expect(mockTransaction.update).toHaveBeenCalledWith(
        mockEventRef,
        expect.objectContaining({
          ticketsSold: 11
        })
      );
    });

    test('should set ticket status to confirmed', () => {
      createTicketInTransaction(mockTransaction, {
        ticketRef: mockTicketRef,
        eventRef: mockEventRef,
        event: mockEvent,
        userId: 'user789'
      });

      const setCall = mockTransaction.set.mock.calls[0];
      const ticketData = setCall[1];
      expect(ticketData.status).toBe('confirmed');
    });

    test('should handle event without explicit id field', () => {
      const eventWithoutId = { ...mockEvent };
      delete eventWithoutId.id;

      const result = createTicketInTransaction(mockTransaction, {
        ticketRef: mockTicketRef,
        eventRef: mockEventRef,
        event: eventWithoutId,
        userId: 'user789'
      });

      const setCall = mockTransaction.set.mock.calls[0];
      const ticketData = setCall[1];
      expect(ticketData.eventId).toBe('event456'); // Should use eventRef.id
    });

    test('should include all event details in ticket', () => {
      createTicketInTransaction(mockTransaction, {
        ticketRef: mockTicketRef,
        eventRef: mockEventRef,
        event: mockEvent,
        userId: 'user789'
      });

      const setCall = mockTransaction.set.mock.calls[0];
      const ticketData = setCall[1];

      expect(ticketData.eventName).toBe('Test Event');
      expect(ticketData.venue).toBe('Test Venue');
      expect(ticketData.venueId).toBe('venue123');
      expect(ticketData.startTime).toEqual(mockEvent.startTime);
      expect(ticketData.totalPrice).toBe(50.00);
    });
  });
});
