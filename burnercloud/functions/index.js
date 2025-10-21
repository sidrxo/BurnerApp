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