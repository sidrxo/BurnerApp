package com.burner.shared.repositories

/**
 * iOS actual implementation of SupabaseClient
 * This is a minimal placeholder - the real Supabase interaction happens in Swift
 */
actual class SupabaseClient {
    actual fun from(table: String): QueryBuilder {
        return QueryBuilder()
    }
}

/**
 * iOS actual implementation of QueryBuilder
 * This is a minimal placeholder - the real query building happens in Swift
 */
actual class QueryBuilder {
    actual fun select(): QueryBuilder = this
    actual fun eq(column: String, value: Any): QueryBuilder = this
    actual fun gt(column: String, value: Any): QueryBuilder = this
    actual fun lt(column: String, value: Any): QueryBuilder = this
    actual fun gte(column: String, value: Any): QueryBuilder = this
    actual fun `in`(column: String, values: List<String>): QueryBuilder = this
    actual fun contains(column: String, values: List<String>): QueryBuilder = this
    actual fun order(column: String, ascending: Boolean): QueryBuilder = this
    actual fun limit(count: Int): QueryBuilder = this
    actual fun range(from: Int, to: Int): QueryBuilder = this

    actual suspend fun <T> execute(): T {
        throw NotImplementedError("Use Swift Supabase client directly - KMP repositories not needed for iOS")
    }

    actual suspend fun <T> executeSingle(): T? {
        throw NotImplementedError("Use Swift Supabase client directly - KMP repositories not needed for iOS")
    }
}

/**
 * iOS actual implementation of QueryBuilder extension for delete operations
 */
actual fun QueryBuilder.delete(): QueryBuilder = this

/**
 * iOS actual implementation of QueryBuilder extension for insert operations
 */
actual fun QueryBuilder.insert(data: Map<String, Any?>): QueryBuilder = this

/**
 * iOS actual implementation of QueryBuilder extension for update operations
 */
actual fun QueryBuilder.update(data: Map<String, Any>): QueryBuilder = this

/**
 * iOS actual implementation of QueryBuilder extension for upsert operations
 */
actual fun QueryBuilder.upsert(data: Any): QueryBuilder = this
