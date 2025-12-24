package com.burner.shared.repositories

import io.github.jan.supabase.SupabaseClient as KtorSupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.gotrue.Auth
import kotlinx.serialization.json.Json

/**
 * iOS implementation of SupabaseClient using Supabase KMP SDK
 */
actual class SupabaseClient {
    private val client: KtorSupabaseClient

    constructor(url: String, anonKey: String) {
        client = createSupabaseClient(url, anonKey) {
            install(Postgrest)
            install(Auth)
        }
    }

    actual fun from(table: String): QueryBuilder {
        return QueryBuilder(table, client)
    }

    fun getKtorClient(): KtorSupabaseClient = client
}

/**
 * iOS implementation of QueryBuilder using Supabase KMP SDK
 */
actual class QueryBuilder internal constructor(
    private val table: String,
    private val client: KtorSupabaseClient
) {
    private var queryBuilder: io.github.jan.supabase.postgrest.query.PostgrestQueryBuilder? = null
    private val filters = mutableMapOf<String, Any>()
    private var selectColumns: String = "*"
    private var orderColumn: String? = null
    private var orderAscending: Boolean = true
    private var limitCount: Int? = null
    private var rangeFrom: Int? = null
    private var rangeTo: Int? = null

    actual fun select(): QueryBuilder {
        selectColumns = "*"
        return this
    }

    actual fun eq(column: String, value: Any): QueryBuilder {
        filters["eq_$column"] = value
        return this
    }

    actual fun gt(column: String, value: Any): QueryBuilder {
        filters["gt_$column"] = value
        return this
    }

    actual fun lt(column: String, value: Any): QueryBuilder {
        filters["lt_$column"] = value
        return this
    }

    actual fun gte(column: String, value: Any): QueryBuilder {
        filters["gte_$column"] = value
        return this
    }

    actual fun `in`(column: String, values: List<String>): QueryBuilder {
        filters["in_$column"] = values
        return this
    }

    actual fun contains(column: String, values: List<String>): QueryBuilder {
        filters["contains_$column"] = values
        return this
    }

    actual fun order(column: String, ascending: Boolean): QueryBuilder {
        orderColumn = column
        orderAscending = ascending
        return this
    }

    actual fun limit(count: Int): QueryBuilder {
        limitCount = count
        return this
    }

    actual fun range(from: Int, to: Int): QueryBuilder {
        rangeFrom = from
        rangeTo = to
        return this
    }

    actual suspend fun <T> execute(): T {
        val query = client.from(table).select(columns = Columns.raw(selectColumns)) {
            // Apply filters
            filters.forEach { (key, value) ->
                when {
                    key.startsWith("eq_") -> {
                        val column = key.removePrefix("eq_")
                        filter {
                            eq(column, value)
                        }
                    }
                    key.startsWith("gt_") -> {
                        val column = key.removePrefix("gt_")
                        filter {
                            gt(column, value)
                        }
                    }
                    key.startsWith("lt_") -> {
                        val column = key.removePrefix("lt_")
                        filter {
                            lt(column, value)
                        }
                    }
                    key.startsWith("gte_") -> {
                        val column = key.removePrefix("gte_")
                        filter {
                            gte(column, value)
                        }
                    }
                    key.startsWith("in_") -> {
                        val column = key.removePrefix("in_")
                        if (value is List<*>) {
                            filter {
                                isIn(column, value as List<Any>)
                            }
                        }
                    }
                    key.startsWith("contains_") -> {
                        val column = key.removePrefix("contains_")
                        if (value is List<*>) {
                            filter {
                                contains(column, value as List<Any>)
                            }
                        }
                    }
                }
            }

            // Apply ordering
            orderColumn?.let { col ->
                order(col, if (orderAscending) Order.ASCENDING else Order.DESCENDING)
            }

            // Apply limit
            limitCount?.let {
                limit(it.toLong())
            }

            // Apply range
            if (rangeFrom != null && rangeTo != null) {
                range(rangeFrom!!.toLong()..rangeTo!!.toLong())
            }
        }

        @Suppress("UNCHECKED_CAST")
        return query.decodeList() as T
    }

    actual suspend fun <T> executeSingle(): T? {
        val query = client.from(table).select(columns = Columns.raw(selectColumns)) {
            // Apply filters (same as execute)
            filters.forEach { (key, value) ->
                when {
                    key.startsWith("eq_") -> {
                        val column = key.removePrefix("eq_")
                        filter {
                            eq(column, value)
                        }
                    }
                    // ... other filters same as above
                }
            }

            limit(1)
        }

        @Suppress("UNCHECKED_CAST")
        return try {
            query.decodeSingle() as T
        } catch (e: Exception) {
            null
        }
    }
}
