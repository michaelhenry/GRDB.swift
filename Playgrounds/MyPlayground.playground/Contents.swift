// To run this playground, select and build the GRDBOSX scheme.

import GRDB


var configuration = Configuration()
configuration.trace = { print($0) }
let dbQueue = DatabaseQueue(configuration: configuration)


var migrator = DatabaseMigrator()
migrator.registerMigration("Employees") { db in
    try db.create(table: "employees") { t in
        t.column("id", .integer).primaryKey()
        t.column("managerId", .integer).references("employees")
        t.column("name", .text)
    }
}
try! migrator.migrate(dbQueue)

class Employee : Record {
    static let manager = belongsTo(optional:Employee.self)
    static let subordinates = hasMany(Employee.self)
    
    override static var databaseTableName: String { return "employees" }
}

try! dbQueue.inDatabase { db in
    try! Employee().fetchAll(db, Employee.subordinates)
    try! Employee().fetchOne(db, Employee.manager)
}
