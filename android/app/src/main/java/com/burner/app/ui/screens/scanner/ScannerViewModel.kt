package com.burner.app.ui.screens.scanner

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.Event
import com.burner.app.data.models.UserRole
import com.burner.app.data.repository.EventRepository
import com.burner.app.services.AuthService
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.functions.FirebaseFunctions
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import org.json.JSONObject
import java.util.*
import javax.inject.Inject

sealed class ScanResult {
    data class Success(val ticketNumber: String, val eventName: String) : ScanResult()
    data class AlreadyUsed(val ticketNumber: String, val scannedAt: String) : ScanResult()
    data class Error(val message: String) : ScanResult()
}

data class ScannerUiState(
    val isLoading: Boolean = true,
    val isProcessing: Boolean = false,
    val canAccessScanner: Boolean = false,
    val selectedEventId: String? = null,
    val availableEvents: List<Event> = emptyList(),
    val scanResult: ScanResult? = null,
    val manualEntry: String = "",
    val errorMessage: String? = null
)

@HiltViewModel
class ScannerViewModel @Inject constructor(
    private val authService: AuthService,
    private val eventRepository: EventRepository,
    private val firestore: FirebaseFirestore,
    private val functions: FirebaseFunctions
) : ViewModel() {

    private val _uiState = MutableStateFlow(ScannerUiState())
    val uiState: StateFlow<ScannerUiState> = _uiState.asStateFlow()

    init {
        checkScannerAccess()
    }

    private fun checkScannerAccess() {
        viewModelScope.launch {
            val userId = authService.currentUserId
            if (userId == null) {
                _uiState.update { it.copy(isLoading = false, canAccessScanner = false) }
                return@launch
            }

            try {
                val userProfile = authService.getUserProfile(userId)
                val hasAccess = userProfile?.role in listOf(
                    UserRole.SCANNER,
                    UserRole.VENUE_ADMIN,
                    UserRole.SUB_ADMIN,
                    UserRole.SITE_ADMIN
                )

                if (hasAccess) {
                    loadTodayEvents(userProfile?.role)
                } else {
                    _uiState.update { it.copy(isLoading = false, canAccessScanner = false) }
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        canAccessScanner = false,
                        errorMessage = "Failed to verify scanner access"
                    )
                }
            }
        }
    }

    private suspend fun loadTodayEvents(userRole: String?) {
        try {
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            val startOfDay = calendar.time

            calendar.add(Calendar.DAY_OF_YEAR, 1)
            val endOfDay = calendar.time

            val events = firestore.collection("events")
                .whereGreaterThanOrEqualTo("startTime", Timestamp(startOfDay))
                .whereLessThan("startTime", Timestamp(endOfDay))
                .get()
                .await()
                .documents
                .mapNotNull { it.toObject(Event::class.java) }
                .sortedBy { it.startTime?.toDate() }

            _uiState.update {
                it.copy(
                    isLoading = false,
                    canAccessScanner = true,
                    availableEvents = events,
                    selectedEventId = events.firstOrNull()?.id
                )
            }
        } catch (e: Exception) {
            _uiState.update {
                it.copy(
                    isLoading = false,
                    canAccessScanner = true,
                    errorMessage = "Failed to load events: ${e.message}"
                )
            }
        }
    }

    fun selectEvent(eventId: String) {
        _uiState.update { it.copy(selectedEventId = eventId) }
    }

    fun updateManualEntry(value: String) {
        _uiState.update { it.copy(manualEntry = value) }
    }

    fun scanQRCode(qrCodeData: String) {
        val eventId = _uiState.value.selectedEventId
        if (eventId == null) {
            _uiState.update { it.copy(errorMessage = "Please select an event first") }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true, scanResult = null, errorMessage = null) }

            try {
                val ticketId = extractTicketId(qrCodeData)

                val data = hashMapOf(
                    "eventId" to eventId,
                    "qrCodeData" to qrCodeData
                )

                // Check if it's a ticket number (TKT format)
                if (ticketId != null && ticketId.startsWith("TKT")) {
                    data["ticketNumber"] = ticketId
                } else if (ticketId != null) {
                    data["ticketId"] = ticketId
                } else {
                    _uiState.update {
                        it.copy(
                            isProcessing = false,
                            scanResult = ScanResult.Error("Invalid QR code format")
                        )
                    }
                    return@launch
                }

                val result = functions
                    .getHttpsCallable("scanTicket")
                    .call(data)
                    .await()

                val resultData = result.data as? Map<*, *>
                handleScanResult(resultData)
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isProcessing = false,
                        scanResult = ScanResult.Error(e.message ?: "Scan failed")
                    )
                }
            }
        }
    }

    fun scanManualEntry() {
        val ticketNumber = _uiState.value.manualEntry.trim()
        if (ticketNumber.isEmpty()) {
            _uiState.update { it.copy(errorMessage = "Please enter a ticket number") }
            return
        }

        val eventId = _uiState.value.selectedEventId
        if (eventId == null) {
            _uiState.update { it.copy(errorMessage = "Please select an event first") }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true, scanResult = null, errorMessage = null) }

            try {
                val data = hashMapOf(
                    "eventId" to eventId,
                    "ticketNumber" to ticketNumber,
                    "qrCodeData" to ticketNumber
                )

                val result = functions
                    .getHttpsCallable("scanTicket")
                    .call(data)
                    .await()

                val resultData = result.data as? Map<*, *>
                handleScanResult(resultData)

                // Clear manual entry on success
                _uiState.update { it.copy(manualEntry = "") }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isProcessing = false,
                        scanResult = ScanResult.Error(e.message ?: "Scan failed")
                    )
                }
            }
        }
    }

    private fun handleScanResult(resultData: Map<*, *>?) {
        if (resultData == null) {
            _uiState.update {
                it.copy(
                    isProcessing = false,
                    scanResult = ScanResult.Error("Invalid response from server")
                )
            }
            return
        }

        val success = resultData["success"] as? Boolean ?: false
        val message = resultData["message"] as? String ?: ""
        val ticket = resultData["ticket"] as? Map<*, *>

        if (success && ticket != null) {
            val ticketNumber = ticket["ticketNumber"] as? String ?: "Unknown"
            val eventName = ticket["eventName"] as? String ?: "Unknown Event"
            val wasAlreadyUsed = resultData["wasAlreadyUsed"] as? Boolean ?: false

            if (wasAlreadyUsed) {
                val usedAt = ticket["usedAt"] as? Map<*, *>
                val scannedAt = formatTimestamp(usedAt)
                _uiState.update {
                    it.copy(
                        isProcessing = false,
                        scanResult = ScanResult.AlreadyUsed(ticketNumber, scannedAt)
                    )
                }
            } else {
                _uiState.update {
                    it.copy(
                        isProcessing = false,
                        scanResult = ScanResult.Success(ticketNumber, eventName)
                    )
                }
            }
        } else {
            _uiState.update {
                it.copy(
                    isProcessing = false,
                    scanResult = ScanResult.Error(message.ifEmpty { "Scan failed" })
                )
            }
        }
    }

    private fun extractTicketId(qrCodeData: String): String? {
        // 1. Try URL extraction (partypass.com/ticket/{ID})
        try {
            if (qrCodeData.contains("partypass.com") && qrCodeData.contains("/ticket/")) {
                val parts = qrCodeData.split("/")
                val ticketIndex = parts.indexOf("ticket")
                if (ticketIndex != -1 && ticketIndex < parts.size - 1) {
                    val ticketId = parts[ticketIndex + 1].split("?").first()
                    if (ticketId.length > 10) {
                        return ticketId
                    }
                }
            }
        } catch (e: Exception) {
            // Continue to next extraction method
        }

        // 2. Try JSON extraction
        try {
            val json = JSONObject(qrCodeData)
            if (json.optString("type") == "EVENT_TICKET") {
                return json.optString("ticketId")
            }
        } catch (e: Exception) {
            // Continue to next extraction method
        }

        // 3. Direct ticket ID or ticket number
        if (qrCodeData.length > 10 || qrCodeData.startsWith("TKT")) {
            return qrCodeData
        }

        return null
    }

    private fun formatTimestamp(timestamp: Map<*, *>?): String {
        if (timestamp == null) return "Unknown time"

        val seconds = (timestamp["_seconds"] as? Number)?.toLong() ?: return "Unknown time"
        val date = Date(seconds * 1000)
        val calendar = Calendar.getInstance()
        calendar.time = date

        return String.format(
            "%02d:%02d",
            calendar.get(Calendar.HOUR_OF_DAY),
            calendar.get(Calendar.MINUTE)
        )
    }

    fun clearScanResult() {
        _uiState.update { it.copy(scanResult = null, errorMessage = null) }
    }

    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }
}
