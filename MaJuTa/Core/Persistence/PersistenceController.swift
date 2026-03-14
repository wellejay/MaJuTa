import CoreData
import OSLog

private let logger = Logger(subsystem: "com.majuta.app", category: "persistence")

final class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "MaJuTa")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Encrypt the store at rest — requires device passcode to decrypt
            container.persistentStoreDescriptions.first?.setOption(
                FileProtectionType.complete as NSObject,
                forKey: NSPersistentStoreFileProtectionKey
            )
        }

        container.loadPersistentStores { _, error in
            if let error {
                logger.error("CoreData load error: \(error.localizedDescription, privacy: .private)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            logger.error("CoreData save failed: \(error.localizedDescription, privacy: .private)")
        }
    }
}
