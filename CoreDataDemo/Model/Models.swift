//
//  Models.swift
//  CoreDataDemo
//
//  Created by Deep on 04/01/22.
//

import Foundation

struct Message: Codable, Equatable {
    let id: String
    let from: Int
    let message: String
    let createdAt: String
    let room: String
    let type: MsgType
    let readStatus: String?
    enum CodingKeys: String, CodingKey {
        case id
        case from = "_from"
        case message = "content"
        case createdAt = "created_at"
        case room
        case type
        case readStatus = "read_status"
    }
    static func ==(lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}

enum MsgType: String, Codable, CodingKey {
    case text
    case image
    case video
}

struct Room: Codable, Equatable {
    let id: String
    let activityDate: String
    let lastMessage: LastMessage
    let members: [Member]
    let roomId: String
    let roomName: String
    let unreadMsgCount: Int
    enum CodingKeys: String, CodingKey {
        case id
        case activityDate = "activity_date"
        case lastMessage = "last_message"
        case members
        case roomId = "room_id"
        case roomName = "room_name"
        case unreadMsgCount = "unread_messages_count"
    }
    static func ==(lhs: Room, rhs: Room) -> Bool {
        return lhs.id == rhs.id && lhs.lastMessage == rhs.lastMessage && lhs.members.sorted(by: { $0.id < $1.id }) == rhs.members.sorted(by: { $0.id < $1.id })
    }
}

struct LastMessage: Codable, Equatable {
    let id: String?
    let from: Int?
    let message: String?
    let createdAt: String?
    let room: String?
    enum CodingKeys: String, CodingKey {
        case id
        case from = "_from"
        case message = "content"
        case createdAt = "created_at"
        case room
    }
    static func ==(lhs: LastMessage, rhs: LastMessage) -> Bool {
        return lhs.id ?? "" == rhs.id ?? ""
    }
}

struct Member: Codable, Equatable {
    let id: Int
    let avatar: Media?
    let firstName: String
    let lastName: String
    enum CodingKeys: String, CodingKey {
        case id
        case avatar
        case firstName = "first_name"
        case lastName = "last_name"
    }
    static func ==(lhs: Member, rhs: Member) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Media: Codable, Equatable {
    let type: String?
    let id: String?
    let file: String?
    let thumbnail: String?
    let owner: Int?
    let publicUrl: String?
    enum CodingKeys: String, CodingKey {
        case type
        case id
        case file
        case thumbnail
        case owner
        case publicUrl = "public_url"
    }
}
