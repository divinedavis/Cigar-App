import Supabase
import Foundation

/// Shared Supabase client.
///
/// Kept as a lazy global so the scaffold can launch without crashing
/// when Config.swift still has placeholder values. First actual call
/// to a Supabase method will fail loudly if URL/key are invalid.
private func makeSupabaseClient() -> SupabaseClient {
    guard let url = URL(string: Config.supabaseURL) else {
        preconditionFailure("Config.supabaseURL is not a valid URL: \(Config.supabaseURL)")
    }
    return SupabaseClient(supabaseURL: url, supabaseKey: Config.supabaseKey)
}

let supabase = makeSupabaseClient()
