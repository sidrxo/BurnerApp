const { initializeApp } = require("firebase-admin/app");

// Initialize Firebase Admin
initializeApp();

// Import modules
const migrations = require('./migrations');
const migrationsPhase4 = require('./migrations-phase4');
const adminManagement = require('./admin/adminManagement');
const userValidation = require('./admin/userValidation');
const venueManagement = require('./venues/venueManagement');
const purchaseTicket = require('./tickets/purchaseTicket');
const ticketQueries = require('./tickets/ticketQueries');

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

// ============ MIGRATIONS PHASE 1-3 ============
exports.migrateCreateVenues = migrations.migrateCreateVenues;
exports.migrateAddVenueIdsToEvents = migrations.migrateAddVenueIdsToEvents;
exports.migrateBookmarksToRoot = migrations.migrateBookmarksToRoot;
exports.verifyMigrationStatus = migrations.verifyMigrationStatus;

// ============ MIGRATIONS PHASE 4 ============
exports.migrateEnhanceVenues = migrationsPhase4.migrateEnhanceVenues;
exports.migrateEnhanceEvents = migrationsPhase4.migrateEnhanceEvents;
exports.migrateEnhanceTickets = migrationsPhase4.migrateEnhanceTickets;
exports.migrateEnhanceUsers = migrationsPhase4.migrateEnhanceUsers;
exports.migrateCreateEventStats = migrationsPhase4.migrateCreateEventStats;
exports.verifyPhase4Status = migrationsPhase4.verifyPhase4Status;