import Foundation

// MARK: - Todo Struct
struct Todo: CustomStringConvertible, Codable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    
    var description: String {
        return "\(isCompleted ? "✅" : "❌") \(title)"
    }
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
    }
}

// MARK: - Cache Protocol
protocol Cache {
    func save(todos: [Todo]) -> Bool
    func load() -> [Todo]?
}

// MARK: - FileSystemCache Class
final class FileSystemCache: Cache {
    private let fileURL: URL
    
    init(filename: String = "todos.json") {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        fileURL = paths[0].appendingPathComponent(filename)
    }
    
    func save(todos: [Todo]) -> Bool {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(todos)
            try data.write(to: fileURL)
            return true
        } catch {
            print("Error saving todos: \(error)")
            return false
        }
    }
    
    func load() -> [Todo]? {
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: fileURL)
            let todos = try decoder.decode([Todo].self, from: data)
            return todos
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
                return []
            } else {
                print("Error loading todos: \(error)")
                return nil
            }
        }
    }
}

// MARK: - InMemoryCache Class
final class InMemoryCache: Cache {
    private var todos: [Todo] = []
    
    func save(todos: [Todo]) -> Bool {
        self.todos = todos
        return true
    }
    
    func load() -> [Todo]? {
        return todos
    }
}

// MARK: - TodosManager Class
final class TodosManager {
    private var todos: [Todo]
    private var cache: Cache
    
    init(cache: Cache) {
        self.cache = cache
        self.todos = cache.load() ?? []
    }
    
    func listTodos() -> [Todo] {
        return todos
    }
    
    func addTodo(with title: String) {
        let newTodo = Todo(title: title)
        todos.append(newTodo)
        _ = cache.save(todos: todos)
    }
    
    func toggleCompletion(forTodoAtIndex index: Int) {
        guard index < todos.count else { return }
        todos[index].isCompleted.toggle()
        _ = cache.save(todos: todos)
    }
    
    func deleteTodo(atIndex index: Int) {
        guard index < todos.count else { return }
        todos.remove(at: index)
        _ = cache.save(todos: todos)
    }
}

// MARK: - App Class & Command Enum
final class App {
    enum Command: String {
        case add
        case list
        case toggle
        case delete
        case exit
    }
    
    private let manager: TodosManager
    
    init(manager: TodosManager) {
        self.manager = manager
    }
    
    func run() {
        while true {
            print("\nEnter command: add, list, toggle, delete, exit")
            guard let input = readLine(), let command = Command(rawValue: input.lowercased()) else {
                print("❗ Invalid command")
                continue
            }
            
            switch command {
            case .add:
                print("Enter title:")
                if let title = readLine(), !title.isEmpty {
                    manager.addTodo(with: title)
                    print("📌 Todo added: \(title)")
                } else {
                    print("❗ Title cannot be empty")
                }
                
            case .list:
                let todos = manager.listTodos()
                for (index, todo) in todos.enumerated() {
                    print("\(index + 1). \(todo)")
                }
                
            case .toggle:
                print("Enter index:")
                if let indexString = readLine(), let index = Int(indexString), index > 0, index <= manager.listTodos().count {
                    manager.toggleCompletion(forTodoAtIndex: index - 1)
                    print("🔄 Todo toggled at index \(index)")
                } else {
                    print("❗ Invalid index")
                }
                
            case .delete:
                print("Enter index:")
                if let indexString = readLine(), let index = Int(indexString), index > 0, index <= manager.listTodos().count {
                    manager.deleteTodo(atIndex: index - 1)
                    print("🗑️ Todo deleted at index \(index)")
                } else {
                    print("❗ Invalid index")
                }
                
            case .exit:
                print("👋 Exiting...")
                return
            }
        }
    }
}

// MARK: - Main
let cache = FileSystemCache() // Or InMemoryCache()
let manager = TodosManager(cache: cache)
let app = App(manager: manager)
app.run()
