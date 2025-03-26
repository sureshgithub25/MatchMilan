//
//  CoreDataManager.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import Foundation
import CoreData

final class CoreDataManager {
    
    // MARK: - Singleton Instance
    static let shared = CoreDataManager()
    private init() {}
    
    // MARK: - Persistent Container Setup
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MatchMilan")
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Core Data store failed to load: \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    // MARK:  Managed Context
    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: Create New Object
    func createObject<T: NSManagedObject>(ofType type: T.Type) -> T {
        let entityName = String(describing: type)
        guard let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? T else {
            fatalError("Unable to create new object for entity: \(entityName)")
        }
        return object
    }
    
    // MARK: - Fetch All Objects
    func fetchAll<T: NSManagedObject>(ofType type: T.Type) -> [T] {
        let entityName = String(describing: type)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        do {
            return (try context.fetch(fetchRequest) as? [T]) ?? []
        } catch {
            debugPrint("Fetch failed for entity \(entityName): \(error)")
            return []
        }
    }
    
    // MARK: - Check If Object Exists
    func objectExists<T: NSManagedObject>(ofType type: T.Type, matchingID id: String, withKey key: String) -> (exists: Bool, objects: [T]) {
        let entityName = String(describing: type)
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = NSPredicate(format: "\(key) == %@", id)
        
        do {
            let results = try context.fetch(request) as? [T] ?? []
            return (!results.isEmpty, results)
        } catch {
            debugPrint("Existence check failed for entity \(entityName): \(error)")
            return (false, [])
        }
    }
    
    // MARK: - Save Context
    func saveChanges() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            debugPrint("Save failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delete Object
    func deleteObject(_ object: NSManagedObject) {
        context.delete(object)
        saveChanges()
    }
}
