//
//  CoreDataManager.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import Foundation
import CoreData

//@objc(UserMatch)
//public class UserMatch: NSManagedObject {
//    @NSManaged public var id: String
//    @NSManaged public var name: String
//    @NSManaged public var address: String
//    @NSManaged public var status: String
//    @NSManaged public var profileImage: String
//}

protocol CoreDataManagerProtocol {
    func createObject<T: NSManagedObject>(ofType type: T.Type) -> T
    func fetchAll<T: NSManagedObject>(ofType type: T.Type) -> [T]
    func objectExists<T: NSManagedObject>(ofType type: T.Type, matchingID id: String, withKey key: String) -> (exists: Bool, objects: [T])
    func saveChanges()
    func deleteObject(_ object: NSManagedObject)
}

final class CoreDataManager: CoreDataManagerProtocol {
    static let shared = CoreDataManager()
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MatchMilan")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func createObject<T: NSManagedObject>(ofType type: T.Type) -> T {
        let entityName = String(describing: type)
        guard let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? T else {
            fatalError("Unable to create new object for entity: \(entityName)")
        }
        return object
    }
    
    func fetchAll<T: NSManagedObject>(ofType type: T.Type) -> [T] {
        let entityName = String(describing: type)
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Fetch failed for entity \(entityName): \(error)")
            return []
        }
    }
    
    func objectExists<T: NSManagedObject>(ofType type: T.Type, matchingID id: String, withKey key: String) -> (exists: Bool, objects: [T]) {
        let entityName = String(describing: type)
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = NSPredicate(format: "\(key) == %@", id)
        
        do {
            let results = try context.fetch(request)
            return (!results.isEmpty, results)
        } catch {
            print("Existence check failed for entity \(entityName): \(error)")
            return (false, [])
        }
    }
    
    func saveChanges() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Save failed: \(error.localizedDescription)")
        }
    }
    
    func deleteObject(_ object: NSManagedObject) {
        context.delete(object)
        saveChanges()
    }
}
