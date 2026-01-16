//
//  DatabaseService.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//
import Foundation
import SQLite3

final class AppDB {
    static let shared = AppDB()

    private var db: OpaquePointer?

    private init() {}

    func open() throws {
        if db != nil { return }

        let url = try FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("app.sqlite")

        if sqlite3_open(url.path, &db) != SQLITE_OK {
            throw NSError(domain: "DB", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to open DB"])
        }

        try exec("PRAGMA foreign_keys = ON;")
        try migrate()
    }

    private func migrate() throws {
        let sql = """
        PRAGMA foreign_keys = ON;

        CREATE TABLE IF NOT EXISTS Profiles (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          isKid INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS ProfileSubscriptions (
          id TEXT PRIMARY KEY,
          profileId TEXT NOT NULL,
          channelId TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY(profileId) REFERENCES Profiles(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS ProfileLikedVideos (
          id TEXT PRIMARY KEY,
          profileId TEXT NOT NULL,
          videoId TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY(profileId) REFERENCES Profiles(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS ProfilePlaylists (
          id TEXT PRIMARY KEY,
          profileId TEXT NOT NULL,
          playlistId TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY(profileId) REFERENCES Profiles(id) ON DELETE CASCADE
        );

        CREATE UNIQUE INDEX IF NOT EXISTS IX_ProfileSubscriptions_UQ ON ProfileSubscriptions(profileId, channelId);
        CREATE UNIQUE INDEX IF NOT EXISTS IX_ProfileLikedVideos_UQ ON ProfileLikedVideos(profileId, videoId);
        CREATE UNIQUE INDEX IF NOT EXISTS IX_ProfilePlaylists_UQ ON ProfilePlaylists(profileId, playlistId);

        CREATE INDEX IF NOT EXISTS IX_ProfileSubscriptions_profileId ON ProfileSubscriptions(profileId);
        CREATE INDEX IF NOT EXISTS IX_ProfileLikedVideos_profileId ON ProfileLikedVideos(profileId);
        CREATE INDEX IF NOT EXISTS IX_ProfilePlaylists_profileId ON ProfilePlaylists(profileId);
        """
        try exec(sql)
    }

    private func exec(_ sql: String) throws {
        var err: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &err) != SQLITE_OK {
            let msg = err.map { String(cString: $0) } ?? "Unknown SQLite error"
            sqlite3_free(err)
            throw NSError(domain: "DB", code: 2, userInfo: [NSLocalizedDescriptionKey: msg])
        }
    }

    func fetchProfiles() throws -> [Profile] {
        let sql = "SELECT id, name, isKid FROM Profiles ORDER BY name COLLATE NOCASE;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw NSError(domain: "DB", code: 3, userInfo: [NSLocalizedDescriptionKey: "prepare failed"])
        }

        var out: [Profile] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = String(cString: sqlite3_column_text(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let isKid = sqlite3_column_int(stmt, 2) == 1
            out.append(Profile(id: id, name: name, isKid: isKid))
        }
        return out
    }

    func createProfile(
        name: String,
        isKid: Bool,
        channelIds: [String],
        videoIds: [String],
        playlistIds: [String]
    ) throws {
        let profileId = UUID().uuidString
        let now = ISO8601DateFormatter().string(from: Date())

        try exec("BEGIN;")
        do {
            // Profiles
            try run(
                "INSERT INTO Profiles (id, name, isKid, createdAt) VALUES (?, ?, ?, ?);",
                binds: { stmt in
                    bindText(stmt, 1, profileId)
                    bindText(stmt, 2, name)
                    sqlite3_bind_int(stmt, 3, isKid ? 1 : 0)
                    bindText(stmt, 4, now)
                }
            )

            // Subscriptions
            for cid in Set(channelIds) {
                try run(
                    "INSERT OR IGNORE INTO ProfileSubscriptions (id, profileId, channelId, createdAt) VALUES (?, ?, ?, ?);",
                    binds: { stmt in
                        bindText(stmt, 1, UUID().uuidString)
                        bindText(stmt, 2, profileId)
                        bindText(stmt, 3, cid)
                        bindText(stmt, 4, now)
                    }
                )
            }

            // Liked videos
            for vid in Set(videoIds) {
                try run(
                    "INSERT OR IGNORE INTO ProfileLikedVideos (id, profileId, videoId, createdAt) VALUES (?, ?, ?, ?);",
                    binds: { stmt in
                        bindText(stmt, 1, UUID().uuidString)
                        bindText(stmt, 2, profileId)
                        bindText(stmt, 3, vid)
                        bindText(stmt, 4, now)
                    }
                )
            }

            // Playlists
            for pid in Set(playlistIds) {
                try run(
                    "INSERT OR IGNORE INTO ProfilePlaylists (id, profileId, playlistId, createdAt) VALUES (?, ?, ?, ?);",
                    binds: { stmt in
                        bindText(stmt, 1, UUID().uuidString)
                        bindText(stmt, 2, profileId)
                        bindText(stmt, 3, pid)
                        bindText(stmt, 4, now)
                    }
                )
            }

            try exec("COMMIT;")
        } catch {
            try? exec("ROLLBACK;")
            throw error
        }
    }

    private func run(_ sql: String, binds: (OpaquePointer?) -> Void) throws {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw NSError(domain: "DB", code: 4, userInfo: [NSLocalizedDescriptionKey: "prepare failed"])
        }
        binds(stmt)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw NSError(domain: "DB", code: 5, userInfo: [NSLocalizedDescriptionKey: msg])
        }
    }

    private func bindText(_ stmt: OpaquePointer?, _ index: Int32, _ value: String) {
        sqlite3_bind_text(stmt, index, value, -1, SQLITE_TRANSIENT)
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

