const { initializeApp } = require("firebase-admin/app");

// Initialize Firebase Admin
initializeApp();

// Import modules
const adminManagement = require('./admin/adminManagement');
const scannerManagement = require('./admin/scannerManagement');
const userValidation = require('./admin/userValidation');
const venueManagement = require('./venues/venueManagement');
const purchaseTicket = require('./tickets/purchaseTicket');
const ticketQueries = require('./tickets/ticketQueries');
const scanTicket = require('./tickets/scanTicket');
const stripePayment = require('./payments/stripePayment');
const ticketTriggers = require('./triggers/ticketTriggers');
const auditTriggers = require('./triggers/auditTriggers');

// ============ ADMIN MANAGEMENT ============
exports.createAdmin = adminManagement.createAdmin;
exports.updateAdmin = adminManagement.updateAdmin;
exports.deleteAdmin = adminManagement.deleteAdmin;

// ============ SCANNER MANAGEMENT ============
exports.createScanner = scannerManagement.createScanner;
exports.updateScanner = scannerManagement.updateScanner;
exports.deleteScanner = scannerManagement.deleteScanner;
exports.getScannerProfile = scannerManagement.getScannerProfile;

// ============ USER VALIDATION ============
exports.validateUser = userValidation.validateUser;

// ============ VENUE MANAGEMENT ============
exports.createVenue = venueManagement.createVenue;

// ============ TICKET OPERATIONS ============
exports.purchaseTicket = purchaseTicket.purchaseTicket;
exports.checkUserTicket = ticketQueries.checkUserTicket;
exports.getUserTickets = ticketQueries.getUserTickets;
exports.scanTicket = scanTicket.scanTicket;
exports.getScanHistory = scanTicket.getScanHistory;

// ============ PAYMENT PROCESSING ============
exports.createPaymentIntent = stripePayment.createPaymentIntent;
exports.confirmPurchase = stripePayment.confirmPurchase;
exports.processApplePayPayment = stripePayment.processApplePayPayment;

// ============ PAYMENT METHOD MANAGEMENT ============
exports.getPaymentMethods = stripePayment.getPaymentMethods;
exports.savePaymentMethod = stripePayment.savePaymentMethod;
exports.deletePaymentMethod = stripePayment.deletePaymentMethod;
exports.setDefaultPaymentMethod = stripePayment.setDefaultPaymentMethod;

// ============ FIRESTORE TRIGGERS ============
// Ticket triggers for eventStats auto-updates
exports.onTicketCreated = ticketTriggers.onTicketCreated;
exports.onTicketUpdated = ticketTriggers.onTicketUpdated;
exports.onTicketDeleted = ticketTriggers.onTicketDeleted;

// Audit triggers for logging admin actions
exports.onAdminCreated = auditTriggers.onAdminCreated;
exports.onAdminUpdated = auditTriggers.onAdminUpdated;
exports.onAdminDeleted = auditTriggers.onAdminDeleted;
exports.onScannerCreated = auditTriggers.onScannerCreated;
exports.onScannerUpdated = auditTriggers.onScannerUpdated;
exports.onScannerDeleted = auditTriggers.onScannerDeleted;
exports.onEventDeleted = auditTriggers.onEventDeleted;
exports.onTicketRefunded = auditTriggers.onTicketRefunded;