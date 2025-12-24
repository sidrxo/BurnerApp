package com.burner.app.ui.screens.scanner

import android.annotation.SuppressLint
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.BurnerSupabaseClient
import com.burner.shared.models.Event
import com.burner.shared.models.UserRole
import com.burner.app.data.repository.EventRepository
import com.burner.app.services.AuthService
import dagger.hilt.android.lifecycle.HiltViewModel
import io.github.jan.supabase.functions.functions
import io.ktor.client.call.body
import io.ktor.client.request.setBody
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import org.json.JSONObject
import java.util.*
import javax.inject.Inject
import kotlin.time.Duration.Companion.days

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

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class ScanTicketRequest(
    @SerialName("ticket_id")
    val ticketId: String? = null,
    @SerialName("ticket_number")
    val ticketNumber: String? = null,
    @SerialName("event_id")
    val eventId: String
)

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class ScanTicketResponse(
    val success: Boolean,
    val message: String? = null,
    val ticket: TicketInfo? = null,
    val errorType: String? = null
)

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class TicketInfo(
    val ticketNumber: String,
    val eventName: String,
    val scannedAt: String? = null,
    val status: String? = null
)

@HiltViewModel
class ScannerViewModel @Inject constructor(
    private val authService: AuthService,
    private val eventRepository: EventRepository,
    private val supabase: BurnerSupabaseClient
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
                // Fetch role from Supabase
                val role = authService.getUserRole() ?: UserRole.USER

                // Allow all authenticated users to access scanner
                loadTodayEvents(role)
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
            val now = Clock.System.now()
            val localDateTime = now.toLocalDateTime(TimeZone.currentSystemDefault())

            // Start of today at midnight
            val todayStr = "${localDateTime.date}T00:00:00Z"
            val startOfDay = Instant.parse(todayStr)
            // End of today (start of tomorrow)
            val endOfDay = startOfDay + 1.days

            // Use EventRepository to get events
            val allEvents = eventRepository.getAllEvents()
            val events = allEvents.filter { event ->
                event.startTime?.let { startTimeStr ->
                    try {
                        val eventStart = Instant.parse(startTimeStr)
                        eventStart >= startOfDay && eventStart < endOfDay
                    } catch (e: Exception) {
                        false
                    }
                } ?: false
            }.sortedBy { it.startTime }

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

                val request = if (ticketId != null && ticketId.startsWith("TKT")) {
                    ScanTicketRequest(
                        eventId = eventId,
                        ticketNumber = ticketId
                    )
                } else if (ticketId != null) {
                    ScanTicketRequest(
                        eventId = eventId,
                        ticketId = ticketId
                    )
                } else {
                    _uiState.update {
                        it.copy(
                            isProcessing = false,
                            scanResult = ScanResult.Error("Invalid QR code format")
                        )
                    }
                    return@launch
                }

                // FIXED: Use correct invoke syntax + response.body()
                val response = supabase.functions.invoke("scan-ticket") {
                    setBody(request)
                }
                val scanResponse = response.body<ScanTicketResponse>()

                handleScanResult(scanResponse)
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
                val request = ScanTicketRequest(
                    eventId = eventId,
                    ticketNumber = ticketNumber
                )

                // FIXED: Use correct invoke syntax + response.body()
                val response = supabase.functions.invoke("scan-ticket") {
                    setBody(request)
                }
                val scanResponse = response.body<ScanTicketResponse>()

                handleScanResult(scanResponse)

                // Clear manual entry on success
                if (scanResponse.success) {
                    _uiState.update { it.copy(manualEntry = "") }
                }
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

    private fun handleScanResult(response: ScanTicketResponse) {
        val ticket = response.ticket

        if (response.success && ticket != null) {
            val ticketNumber = ticket.ticketNumber
            val eventName = ticket.eventName

            // Check if ticket was already used based on error type
            val wasAlreadyUsed = response.errorType == "ALREADY_USED"

            if (wasAlreadyUsed) {
                val scannedAt = formatTimestamp(ticket.scannedAt)
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
                    scanResult = ScanResult.Error(response.message ?: "Scan failed")
                )
            }
        }
    }

    private fun extractTicketId(qrCodeData: String): String? {
        // 1. Try URL extraction (burnerapp.com/ticket/{ID})
        try {
            if (qrCodeData.contains("burnerapp.com") && qrCodeData.contains("/ticket/")) {
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
                return json.optString("ticket_id") ?: json.optString("ticketId")
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

    private fun formatTimestamp(timestamp: String?): String {
        if (timestamp == null) return "Unknown time"

        return try {
            val instant = Instant.parse(timestamp)
            val localDateTime = instant.toLocalDateTime(TimeZone.currentSystemDefault())
            String.format(
                "%02d:%02d",
                localDateTime.hour,
                localDateTime.minute
            )
        } catch (e: Exception) {
            "Unknown time"
        }
    }

    fun clearScanResult() {
        _uiState.update { it.copy(scanResult = null, errorMessage = null) }
    }

    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }
}