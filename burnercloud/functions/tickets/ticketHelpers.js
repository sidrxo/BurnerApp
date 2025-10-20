const crypto = require("crypto");

function generateQRCodeData(ticketId, eventId, userId, ticketNumber) {
  try {
    const qrData = {
      type: "EVENT_TICKET",
      ticketId: ticketId,
      eventId: eventId,
      userId: userId,
      ticketNumber: ticketNumber,
      timestamp: Date.now(),
      version: "1.0",
      hash: generateSecurityHash(ticketId, eventId, userId)
    };
    
    return JSON.stringify(qrData);
  } catch (error) {
    console.error("QR Code generation error:", error.message);
    return `TICKET:${ticketId}:EVENT:${eventId}:USER:${userId}:NUMBER:${ticketNumber}`;
  }
}

function generateSecurityHash(ticketId, eventId, userId) {
  try {
    const secret = process.env.QR_SECRET || "default_secret_change_in_production";
    const data = `${ticketId}:${eventId}:${userId}`;
    return crypto.createHmac('sha256', secret).update(data).digest('hex').substring(0, 16);
  } catch (error) {
    console.error("Hash generation error:", error.message);
    return "fallback_hash";
  }
}

function generateTicketNumber() {
  try {
    const timestamp = Date.now().toString().slice(-6);
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, "0");
    const checksum = (parseInt(timestamp) + parseInt(random)) % 100;
    return `TKT${timestamp}${random}${checksum.toString().padStart(2, "0")}`;
  } catch (error) {
    console.error("Ticket number generation error:", error.message);
    return `TKT${Date.now()}${Math.floor(Math.random() * 1000)}`;
  }
}

module.exports = {
  generateQRCodeData,
  generateSecurityHash,
  generateTicketNumber
};