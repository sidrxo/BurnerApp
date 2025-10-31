const {
  validateTicketAvailability,
  initiateRefund
} = require('../payments/paymentHelpers');

const { HttpsError } = require('firebase-functions/v2/https');

// Mock Firestore
jest.mock('firebase-admin/firestore', () => ({
  getFirestore: jest.fn(),
  FieldValue: {
    serverTimestamp: jest.fn(() => 'TIMESTAMP')
  }
}));

const { getFirestore } = require('firebase-admin/firestore');

describe('Payment Helpers', () => {
  let mockDb;
  let mockCollection;
  let mockWhere;
  let mockLimit;
  let mockGet;

  beforeEach(() => {
    mockGet = jest.fn();
    mockLimit = jest.fn(() => ({ get: mockGet }));
    mockWhere = jest.fn(() => ({
      where: mockWhere,
      limit: mockLimit,
      get: mockGet
    }));
    mockCollection = jest.fn(() => ({
      where: mockWhere,
      doc: jest.fn()
    }));
    mockDb = {
      collection: mockCollection
    };
    getFirestore.mockReturnValue(mockDb);
    jest.clearAllMocks();
  });

  describe('validateTicketAvailability', () => {
    test('should throw error if user already has ticket for event', async () => {
      // Mock existing ticket found
      mockGet.mockResolvedValue({
        empty: false,
        docs: [{ id: 'ticket123' }]
      });

      await expect(validateTicketAvailability('user123', 'event456'))
        .rejects.toThrow(HttpsError);

      expect(mockCollection).toHaveBeenCalledWith('tickets');
      expect(mockWhere).toHaveBeenCalledWith('userId', '==', 'user123');
      expect(mockWhere).toHaveBeenCalledWith('eventId', '==', 'event456');
      expect(mockWhere).toHaveBeenCalledWith('status', '==', 'confirmed');
    });

    test('should throw error if event not found', async () => {
      // No existing ticket
      mockGet.mockResolvedValueOnce({
        empty: true
      });

      // Event doesn't exist
      const mockEventDoc = {
        exists: false
      };
      const mockEventRef = {
        get: jest.fn().mockResolvedValue(mockEventDoc)
      };
      mockCollection.mockReturnValueOnce({
        where: mockWhere
      }).mockReturnValueOnce({
        doc: jest.fn().mockReturnValue(mockEventRef)
      });

      await expect(validateTicketAvailability('user123', 'event456'))
        .rejects.toThrow(HttpsError);
    });

    test('should throw error if no tickets available', async () => {
      // No existing ticket
      mockGet.mockResolvedValueOnce({
        empty: true
      });

      // Event exists but sold out
      const mockEventDoc = {
        exists: true,
        data: () => ({
          maxTickets: 100,
          ticketsSold: 100
        })
      };
      const mockEventRef = {
        get: jest.fn().mockResolvedValue(mockEventDoc)
      };
      mockCollection.mockReturnValueOnce({
        where: mockWhere
      }).mockReturnValueOnce({
        doc: jest.fn().mockReturnValue(mockEventRef)
      });

      await expect(validateTicketAvailability('user123', 'event456'))
        .rejects.toThrow(HttpsError);
    });

    test('should return event data when validation passes', async () => {
      // No existing ticket
      mockGet.mockResolvedValueOnce({
        empty: true
      });

      // Event exists with available tickets
      const eventData = {
        name: 'Test Event',
        maxTickets: 100,
        ticketsSold: 50,
        price: 25.00
      };
      const mockEventDoc = {
        exists: true,
        data: () => eventData
      };
      const mockEventRef = {
        get: jest.fn().mockResolvedValue(mockEventDoc)
      };
      mockCollection.mockReturnValueOnce({
        where: mockWhere
      }).mockReturnValueOnce({
        doc: jest.fn().mockReturnValue(mockEventRef)
      });

      const result = await validateTicketAvailability('user123', 'event456');

      expect(result.event).toEqual(eventData);
      expect(result.eventRef).toBeDefined();
      expect(result.eventDoc).toBeDefined();
    });

    test('should work with transaction parameter', async () => {
      // No existing ticket
      mockGet.mockResolvedValueOnce({
        empty: true
      });

      // Mock transaction
      const mockTransaction = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({
            maxTickets: 100,
            ticketsSold: 50
          })
        })
      };

      const mockEventRef = {
        get: jest.fn()
      };
      mockCollection.mockReturnValueOnce({
        where: mockWhere
      }).mockReturnValueOnce({
        doc: jest.fn().mockReturnValue(mockEventRef)
      });

      const result = await validateTicketAvailability('user123', 'event456', mockTransaction);

      expect(mockTransaction.get).toHaveBeenCalledWith(mockEventRef);
      expect(mockEventRef.get).not.toHaveBeenCalled(); // Should use transaction instead
      expect(result.event).toBeDefined();
    });

    test('should allow ticket purchase when 1 ticket remains', async () => {
      mockGet.mockResolvedValueOnce({
        empty: true
      });

      const mockEventDoc = {
        exists: true,
        data: () => ({
          maxTickets: 100,
          ticketsSold: 99
        })
      };
      const mockEventRef = {
        get: jest.fn().mockResolvedValue(mockEventDoc)
      };
      mockCollection.mockReturnValueOnce({
        where: mockWhere
      }).mockReturnValueOnce({
        doc: jest.fn().mockReturnValue(mockEventRef)
      });

      await expect(validateTicketAvailability('user123', 'event456'))
        .resolves.toBeDefined();
    });

    test('should check for confirmed status only', async () => {
      // User has refunded ticket, should still allow new purchase
      mockGet.mockResolvedValueOnce({
        empty: true // No confirmed tickets found
      });

      const mockEventDoc = {
        exists: true,
        data: () => ({
          maxTickets: 100,
          ticketsSold: 50
        })
      };
      const mockEventRef = {
        get: jest.fn().mockResolvedValue(mockEventDoc)
      };
      mockCollection.mockReturnValueOnce({
        where: mockWhere
      }).mockReturnValueOnce({
        doc: jest.fn().mockReturnValue(mockEventRef)
      });

      await expect(validateTicketAvailability('user123', 'event456'))
        .resolves.toBeDefined();

      // Verify status filter was applied
      expect(mockWhere).toHaveBeenCalledWith('status', '==', 'confirmed');
    });
  });

  describe('initiateRefund', () => {
    let mockStripe;

    beforeEach(() => {
      mockStripe = {
        refunds: {
          create: jest.fn()
        }
      };
    });

    test('should create refund with default reason', async () => {
      const mockRefund = {
        id: 'refund_123',
        status: 'succeeded',
        amount: 5000
      };
      mockStripe.refunds.create.mockResolvedValue(mockRefund);

      const result = await initiateRefund(mockStripe, 'pi_123456');

      expect(mockStripe.refunds.create).toHaveBeenCalledWith({
        payment_intent: 'pi_123456',
        reason: 'requested_by_customer'
      });
      expect(result).toEqual(mockRefund);
    });

    test('should create refund with custom reason', async () => {
      const mockRefund = {
        id: 'refund_123',
        status: 'succeeded'
      };
      mockStripe.refunds.create.mockResolvedValue(mockRefund);

      await initiateRefund(mockStripe, 'pi_123456', 'duplicate');

      expect(mockStripe.refunds.create).toHaveBeenCalledWith({
        payment_intent: 'pi_123456',
        reason: 'duplicate'
      });
    });

    test('should handle refund errors', async () => {
      mockStripe.refunds.create.mockRejectedValue(new Error('Stripe error'));

      await expect(initiateRefund(mockStripe, 'pi_123456'))
        .rejects.toThrow('Stripe error');
    });

    test('should return refund object on success', async () => {
      const mockRefund = {
        id: 'refund_123',
        status: 'succeeded',
        amount: 5000,
        payment_intent: 'pi_123456'
      };
      mockStripe.refunds.create.mockResolvedValue(mockRefund);

      const result = await initiateRefund(mockStripe, 'pi_123456');

      expect(result).toEqual(mockRefund);
    });

    test('should support all valid Stripe refund reasons', async () => {
      const reasons = ['duplicate', 'fraudulent', 'requested_by_customer'];

      for (const reason of reasons) {
        mockStripe.refunds.create.mockResolvedValue({ id: 'refund_123' });

        await initiateRefund(mockStripe, 'pi_123456', reason);

        expect(mockStripe.refunds.create).toHaveBeenCalledWith({
          payment_intent: 'pi_123456',
          reason: reason
        });
      }
    });
  });
});
