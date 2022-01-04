//
//  CoreDataManager.swift
//  CoreDataDemo
//
//  Created by Deep on 04/01/22.
//

import CoreData

final class CoreDataManager {
    
    private init(){}
    static let shared = CoreDataManager()
    
    let cdMessage = "CDMessage"
    let cdRoom = "CDRoom"
    let cdLastMessage = "CDLastMessage"
    let cdMember = "CDMember"
    let cdMedia = "CDMedia"
    
    // MARK: - Model Message CRUD
    func createMessages(messages: [Message], roomId: String) {
        let context = PersistentStorage.shared.newBackgroundContext()
        context.perform {
            messages.forEach { message in
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.cdMessage)
                fetchRequest.predicate = NSPredicate(format: "id==%@", message.id as CVarArg)
                fetchRequest.fetchLimit = 1
                do {
                    let countRequest = try context.count(for: fetchRequest)
                    if countRequest == 0 {
                        let cdMessage = CDMessage(context: context)
                        cdMessage.id = message.id
                        cdMessage.message = message.message
                        cdMessage.from = Int64(message.from)
                        cdMessage.createdAt = message.createdAt
                        cdMessage.room = message.room
                        cdMessage.type = message.type.rawValue
                        cdMessage.readStatus = message.readStatus
                        cdMessage.roomId = roomId
                    }
                } catch let error {
                    debugPrint(error)
                }
            }
            context.saveContext()
        }
    }
    
    func readAllMessages() -> [Message]? {
        let result = PersistentStorage.shared.fetchManagedObject(managedObject: CDMessage.self)
        var messages : [Message] = []
        result?.forEach({ (cdMessage) in
            messages.append(cdMessage.convertToMessage())
        })
        return messages
    }
    
    func readMessages(byIdentifier roomId: String) -> [Message]? {
        let fetchRequest = NSFetchRequest<CDMessage>(entityName: self.cdMessage)
        fetchRequest.predicate = NSPredicate(format: "roomId==%@", roomId as CVarArg)
        var messages : [Message] = []
        do {
            let result = try PersistentStorage.shared.context.fetch(fetchRequest)
            result.forEach({ (cdMessage) in
                messages.append(cdMessage.convertToMessage())
            })
        } catch let error {
            debugPrint(error)
        }
        return messages
    }
    
    func deleteMessage(messageId: String) {
        let context = PersistentStorage.shared.newBackgroundContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.cdMessage)
        fetchRequest.predicate = NSPredicate(format: "id==%@", messageId as CVarArg)
        fetchRequest.fetchLimit = 1
        context.perform {
            context.removeObjects(fetchRequest: fetchRequest)
            context.saveContext()
        }
    }
    
    func deleteMessages(roomId: String) {
        let context = PersistentStorage.shared.newBackgroundContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.cdMessage)
        fetchRequest.predicate = NSPredicate(format: "roomId==%@", roomId as CVarArg)
        context.perform {
            context.removeObjects(fetchRequest: fetchRequest)
            context.saveContext()
        }
    }
    
    private func deleteAllMessage() {
        self.deleteEntity(entityName: self.cdMessage)
    }
    
    // MARK: - Model Room CRUD
    func createRooms(rooms: [Room]) {
        let context = PersistentStorage.shared.newBackgroundContext()
        context.perform {
            rooms.forEach { room in
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.cdRoom)
                fetchRequest.predicate = NSPredicate(format: "id==%@", room.id as CVarArg)
                fetchRequest.fetchLimit = 1
                do {
                    let countRequest = try context.count(for: fetchRequest)
                    if countRequest == 0 {
                        let cdRoom = CDRoom(context: context)
                        cdRoom.id = room.id
                        cdRoom.activityDate = room.activityDate
                        cdRoom.roomId = room.roomId
                        cdRoom.roomName = room.roomName
                        cdRoom.unreadMsgCount = Int64(room.unreadMsgCount)
                        
                        let cdLastMessage = CDLastMessage(context: context)
                        cdLastMessage.id = room.lastMessage.id
                        cdLastMessage.createdAt = room.lastMessage.createdAt
                        cdLastMessage.from = Int64(room.lastMessage.from ?? -1)
                        cdLastMessage.message = room.lastMessage.message
                        cdLastMessage.room = room.lastMessage.room
                        cdRoom.toLastMessage = cdLastMessage
                        
                        var cdMembersArray: [Any] = []
                        room.members.forEach { member in
                            let cdMember = CDMember(context: context)
                            cdMember.id = Int64(member.id)
                            cdMember.firstName = member.firstName
                            cdMember.lastName = member.lastName
                            
                            if let media = member.avatar {
                                let cdMedia = CDMedia(context: context)
                                cdMedia.id = media.id
                                cdMedia.type = media.type
                                cdMedia.file = media.file
                                cdMedia.thumbnail = media.thumbnail
                                cdMedia.owner = Int64(media.owner ?? -1)
                                cdMedia.publicUrl = media.publicUrl
                                cdMember.toMedia = cdMedia
                            }
                            cdMembersArray.append(cdMember)
                        }
                        cdRoom.toMembers = NSSet(array: cdMembersArray)
                    }
                } catch let error {
                    debugPrint(error)
                }
            }
            context.saveContext()
        }
    }
    
    func readAllRooms() -> [Room]? {
        let result = PersistentStorage.shared.fetchManagedObject(managedObject: CDRoom.self)
        var rooms : [Room] = []
        result?.forEach({ (cdRoom) in
            rooms.append(cdRoom.convertToRoom())
        })
        return rooms
    }
    
    func deleteRoom(roomId: String) {
        let context = PersistentStorage.shared.newBackgroundContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.cdRoom)
        fetchRequest.predicate = NSPredicate(format: "id==%@", roomId as CVarArg)
        fetchRequest.fetchLimit = 1
        context.perform {
            context.removeObjects(fetchRequest: fetchRequest)
            context.saveContext()
        }
    }
    
    private func deleteAllRooms() {
        self.deleteEntity(entityName: self.cdRoom)
        self.deleteAllLastMessages()
        self.deleteAllMembers()
        self.deleteAllMedia()
    }
    
    // MARK: - Model LastMessage CRUD
    private func deleteAllLastMessages() {
        self.deleteEntity(entityName: self.cdLastMessage)
    }
    
    // MARK: - Model Member CRUD
    private func deleteAllMembers() {
        self.deleteEntity(entityName: self.cdMember)
    }
    
    // MARK: - Model Media CRUD
    private func deleteAllMedia() {
        self.deleteEntity(entityName: self.cdMedia)
    }
    
    // MARK: - Delete Entity
    private func deleteEntity(entityName: String) {
        let context = PersistentStorage.shared.newBackgroundContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        context.perform {
            context.removeObjects(fetchRequest: fetchRequest)
            context.saveContext()
        }
    }
    
    // MARK: - Whole CoreData CRUD
    func deleteAllLocalStorage() {
        self.deleteAllMessage()
        self.deleteAllRooms()
    }
}

// MARK: - NSManagedObject Extension
extension CDMessage {
    func convertToMessage() -> Message {
        return Message(id: self.id ?? "", from: Int(self.from), message: self.message ?? "", createdAt: self.createdAt ?? "", room: self.room ?? "", type: MsgType(rawValue: self.type ?? "text") ?? .text, readStatus: self.readStatus ?? "")
    }
}

extension CDRoom {
    func convertToRoom() -> Room {
        var members : [Member] = []
        let set = self.toMembers
        let cdMemberArray = set?.allObjects as? [CDMember]
        cdMemberArray?.forEach({ member in
            members.append(member.convertToMember())
        })
        return Room(id: self.id ?? "", activityDate: self.activityDate ?? "", lastMessage: self.toLastMessage?.convertToLastMessage() ?? LastMessage(id: nil, from: nil, message: nil, createdAt: nil, room: nil) , members: members, roomId: self.roomId ?? "", roomName: self.roomName ?? "", unreadMsgCount: Int(self.unreadMsgCount))
    }
}

extension CDLastMessage {
    func convertToLastMessage() -> LastMessage {
        return LastMessage(id: self.id ?? "", from: Int(self.from), message: self.message ?? "", createdAt: self.createdAt ?? "", room: self.room ?? "")
    }
}

extension CDMember {
    func convertToMember() -> Member {
        return Member(id: Int(self.id), avatar: self.toMedia?.convertToMedia(), firstName: self.firstName ?? "", lastName: self.lastName ?? "")
    }
}

extension CDMedia {
    func convertToMedia() -> Media {
        return Media(type: self.type ?? "", id: self.id ?? "", file: self.file ?? "", thumbnail: self.thumbnail ?? "", owner: Int(self.owner), publicUrl: self.publicUrl ?? "")
    }
}
