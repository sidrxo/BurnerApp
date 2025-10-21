const { initializeApp } = require("firebase-admin/app");

// Initialize Firebase Admin
initializeApp();

// Import modules
const adminManagement = require('./admin/adminManagement');
const userValidation = require('./admin/userValidation');
const venueManagement = require('./venues/venueManagement');
const purchaseTicket = require('./tickets/purchaseTicket');
const ticketQueries = require('./tickets/ticketQueries');
const stripePayment = require('./payments/stripePayment');
const scannerManagement = require('./admin/scannerManagement');


// ============ ADMIN MANAGEMENT ============
exports.createAdmin = adminManagement.createAdmin;
exports.updateAdmin = adminManagement.updateAdmin;
exports.deleteAdmin = adminManagement.deleteAdmin;

// ============ USER VALIDATION ============
exports.validateUser = userValidation.validateUser;

// ============ VENUE MANAGEMENT ============
exports.createVenue = venueManagement.createVenue;

// ============ TICKET OPERATIONS ============
exports.purchaseTicket = purchaseTicket.purchaseTicket;
exports.checkUserTicket = ticketQueries.checkUserTicket;
exports.getUserTickets = ticketQueries.getUserTickets;

// ============ PAYMENT PROCESSING ============
exports.createPaymentIntent = stripePayment.createPaymentIntent;
exports.confirmPurchase = stripePayment.confirmPurchase;
exports.processApplePayPayment = stripePayment.processApplePayPayment;

// ============ PAYMENT METHOD MANAGEMENT ============
exports.getPaymentMethods = stripePayment.getPaymentMethods;
exports.savePaymentMethod = stripePayment.savePaymentMethod;
exports.deletePaymentMethod = stripePayment.deletePaymentMethod;
exports.setDefaultPaymentMethod = stripePayment.setDefaultPaymentMethod;

// ============ SCANNER MANAGEMENT ============
exports.createScanner = scannerManagement.createScanner;
exports.setScannerStatus = scannerManagement.setScannerStatus;
exports.deleteScanner = scannerManagement.deleteScanner;
