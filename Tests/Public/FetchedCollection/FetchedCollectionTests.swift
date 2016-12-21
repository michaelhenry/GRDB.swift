import XCTest
#if USING_SQLCIPHER
    import GRDBCipher
#elseif USING_CUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

private struct AnyRowConvertible: RowConvertible, Equatable {
    let row: Row
    
    init(row: Row) {
        self.row = row.copy()
    }
    
    static func == (lhs: AnyRowConvertible, rhs: AnyRowConvertible) -> Bool {
        return lhs.row == rhs.row
    }
}

class FetchedCollectionTests : GRDBTestCase {
    
    func testFetchedCollectionFetch() {
        assertNoError {
            let dbPool = try makeDatabasePool()
            let sql = "SELECT NULL AS ignored, ? AS name, ? AS id UNION ALL SELECT NULL, ?, ?"
            let arguments: StatementArguments = ["a", 1, "b", 2]
            let adapter = SuffixRowAdapter(fromIndex: 1)
            let sqlRequest = SQLRequest(sql, arguments: arguments, adapter: adapter)
            
            let valuesFromSQL = try FetchedCollection<String>(dbPool, sql: sql, arguments: arguments, adapter: adapter)
            let valuesFromRequest = try FetchedCollection(dbPool, request: sqlRequest.bound(to: String.self))
            let optionalValuesFromSQL = try FetchedCollection<String?>(dbPool, sql: sql, arguments: arguments, adapter: adapter)
            let optionalValuesFromRequest = try FetchedCollection(dbPool, request: sqlRequest.bound(to: Optional<String>.self))
            let rowsFromSQL = try FetchedCollection<Row>(dbPool, sql: sql, arguments: arguments, adapter: adapter)
            let rowsFromRequest = try FetchedCollection(dbPool, request: sqlRequest.bound(to: Row.self))
            let recordsFromSQL = try FetchedCollection<AnyRowConvertible>(dbPool, sql: sql, arguments: arguments, adapter: adapter)
            let recordsFromRequest = try FetchedCollection(dbPool, request: sqlRequest.bound(to: AnyRowConvertible.self))
            
            try valuesFromSQL.fetch()
            try valuesFromRequest.fetch()
            try optionalValuesFromSQL.fetch()
            try optionalValuesFromRequest.fetch()
            try rowsFromSQL.fetch()
            try rowsFromRequest.fetch()
            try recordsFromSQL.fetch()
            try recordsFromRequest.fetch()
            
            XCTAssertEqual(Array(valuesFromSQL), ["a", "b"])
            XCTAssertEqual(Array(valuesFromRequest), ["a", "b"])
            XCTAssertEqual(Array(optionalValuesFromSQL).map { $0! }, ["a", "b"])
            XCTAssertEqual(Array(optionalValuesFromRequest).map { $0! }, ["a", "b"])
            XCTAssertEqual(Array(rowsFromSQL), [["name": "a", "id": 1], ["name": "b", "id": 2]])
            XCTAssertEqual(Array(rowsFromRequest), [["name": "a", "id": 1], ["name": "b", "id": 2]])
            XCTAssertEqual(Array(recordsFromSQL), [AnyRowConvertible(row: ["name": "a", "id": 1]), AnyRowConvertible(row: ["name": "b", "id": 2])])
            XCTAssertEqual(Array(recordsFromRequest), [AnyRowConvertible(row: ["name": "a", "id": 1]), AnyRowConvertible(row: ["name": "b", "id": 2])])
        }
    }
    
    func testFetchedCollectionAsCollection() {
        assertNoError {
            let dbPool = try makeDatabasePool()
            let sql = "SELECT ? AS name, ? AS id UNION ALL SELECT ?, ?"
            let arguments: StatementArguments = ["a", 1, "b", 2]
            let sqlRequest = SQLRequest(sql, arguments: arguments)
            
            let valuesFromSQL = try FetchedCollection<String>(dbPool, sql: sql, arguments: arguments)
            let valuesFromRequest = try FetchedCollection(dbPool, request: sqlRequest.bound(to: String.self))
            let optionalValuesFromSQL = try FetchedCollection<String?>(dbPool, sql: sql, arguments: arguments)
            let optionalValuesFromRequest = try FetchedCollection(dbPool, request: sqlRequest.bound(to: Optional<String>.self))
            let rowsFromSQL = try FetchedCollection<Row>(dbPool, sql: sql, arguments: arguments)
            let rowsFromRequest = try FetchedCollection(dbPool, request: sqlRequest.bound(to: Row.self))
            let recordsFromSQL = try FetchedCollection<AnyRowConvertible>(dbPool, sql: sql, arguments: arguments)
            let recordsFromRequest = try FetchedCollection(dbPool, request: sqlRequest.bound(to: AnyRowConvertible.self))
            
            try valuesFromSQL.fetch()
            try valuesFromRequest.fetch()
            try optionalValuesFromSQL.fetch()
            try optionalValuesFromRequest.fetch()
            try rowsFromSQL.fetch()
            try rowsFromRequest.fetch()
            try recordsFromSQL.fetch()
            try recordsFromRequest.fetch()
            
            XCTAssertFalse(valuesFromSQL.isEmpty)
            XCTAssertFalse(valuesFromRequest.isEmpty)
            XCTAssertFalse(optionalValuesFromSQL.isEmpty)
            XCTAssertFalse(optionalValuesFromRequest.isEmpty)
            XCTAssertFalse(rowsFromSQL.isEmpty)
            XCTAssertFalse(rowsFromRequest.isEmpty)
            XCTAssertFalse(recordsFromSQL.isEmpty)
            XCTAssertFalse(recordsFromRequest.isEmpty)
            
            XCTAssertEqual(valuesFromSQL.count, 2)
            XCTAssertEqual(valuesFromRequest.count, 2)
            XCTAssertEqual(optionalValuesFromSQL.count, 2)
            XCTAssertEqual(optionalValuesFromRequest.count, 2)
            XCTAssertEqual(rowsFromSQL.count, 2)
            XCTAssertEqual(rowsFromRequest.count, 2)
            XCTAssertEqual(recordsFromSQL.count, 2)
            XCTAssertEqual(recordsFromRequest.count, 2)
            
            XCTAssertEqual(valuesFromSQL.startIndex, 0)
            XCTAssertEqual(valuesFromRequest.startIndex, 0)
            XCTAssertEqual(optionalValuesFromSQL.startIndex, 0)
            XCTAssertEqual(optionalValuesFromRequest.startIndex, 0)
            XCTAssertEqual(rowsFromSQL.startIndex, 0)
            XCTAssertEqual(rowsFromRequest.startIndex, 0)
            XCTAssertEqual(recordsFromSQL.startIndex, 0)
            XCTAssertEqual(recordsFromRequest.startIndex, 0)
            
            XCTAssertEqual(valuesFromSQL.endIndex, 2)
            XCTAssertEqual(valuesFromRequest.endIndex, 2)
            XCTAssertEqual(optionalValuesFromSQL.endIndex, 2)
            XCTAssertEqual(optionalValuesFromRequest.endIndex, 2)
            XCTAssertEqual(rowsFromSQL.endIndex, 2)
            XCTAssertEqual(rowsFromRequest.endIndex, 2)
            XCTAssertEqual(recordsFromSQL.endIndex, 2)
            XCTAssertEqual(recordsFromRequest.endIndex, 2)
            
            XCTAssertEqual(valuesFromSQL[0], "a")
            XCTAssertEqual(valuesFromRequest[0], "a")
            XCTAssertEqual(optionalValuesFromSQL[0], "a")
            XCTAssertEqual(optionalValuesFromRequest[0], "a")
            XCTAssertEqual(rowsFromSQL[0], ["name": "a", "id": 1])
            XCTAssertEqual(rowsFromRequest[0], ["name": "a", "id": 1])
            XCTAssertEqual(recordsFromSQL[0], AnyRowConvertible(row: ["name": "a", "id": 1]))
            XCTAssertEqual(recordsFromRequest[0], AnyRowConvertible(row: ["name": "a", "id": 1]))
            
            XCTAssertEqual(valuesFromSQL[1], "b")
            XCTAssertEqual(valuesFromRequest[1], "b")
            XCTAssertEqual(optionalValuesFromSQL[1], "b")
            XCTAssertEqual(optionalValuesFromRequest[1], "b")
            XCTAssertEqual(rowsFromSQL[1], ["name": "b", "id": 2])
            XCTAssertEqual(rowsFromRequest[1], ["name": "b", "id": 2])
            XCTAssertEqual(recordsFromSQL[1], AnyRowConvertible(row: ["name": "b", "id": 2]))
            XCTAssertEqual(recordsFromRequest[1], AnyRowConvertible(row: ["name": "b", "id": 2]))
            
            XCTAssertEqual(Array(valuesFromSQL.reversed()), ["b", "a"])
            XCTAssertEqual(Array(valuesFromRequest.reversed()), ["b", "a"])
            XCTAssertEqual(Array(optionalValuesFromSQL.reversed()).map { $0! }, ["b", "a"])
            XCTAssertEqual(Array(optionalValuesFromRequest.reversed()).map { $0! }, ["b", "a"])
            XCTAssertEqual(Array(rowsFromSQL.reversed()), [["name": "b", "id": 2], ["name": "a", "id": 1]])
            XCTAssertEqual(Array(rowsFromRequest.reversed()), [["name": "b", "id": 2], ["name": "a", "id": 1]])
            XCTAssertEqual(Array(recordsFromSQL.reversed()), [AnyRowConvertible(row: ["name": "b", "id": 2]), AnyRowConvertible(row: ["name": "a", "id": 1])])
            XCTAssertEqual(Array(recordsFromRequest.reversed()), [AnyRowConvertible(row: ["name": "b", "id": 2]), AnyRowConvertible(row: ["name": "a", "id": 1])])
        }
    }
    
    func testEmptyFetchedCollection() {
        assertNoError {
            let dbPool = try makeDatabasePool()
            let sql = "SELECT 'ignored' WHERE 0"
            let sqlRequest = SQLRequest(sql)
            
            let valuesFromSQL = try FetchedCollection<String>(dbPool, sql: sql)
            let valuesFromRequest = try FetchedCollection(dbPool, request: sqlRequest.bound(to: String.self))
            let optionalValuesFromSQL = try FetchedCollection<String?>(dbPool, sql: sql)
            let optionalValuesFromRequest = try FetchedCollection(dbPool, request: sqlRequest.bound(to: Optional<String>.self))
            let rowsFromSQL = try FetchedCollection<Row>(dbPool, sql: sql)
            let rowsFromRequest = try FetchedCollection(dbPool, request: sqlRequest.bound(to: Row.self))
            let recordsFromSQL = try FetchedCollection<AnyRowConvertible>(dbPool, sql: sql)
            let recordsFromRequest = try FetchedCollection(dbPool, request: sqlRequest.bound(to: AnyRowConvertible.self))
            
            try valuesFromSQL.fetch()
            try valuesFromRequest.fetch()
            try optionalValuesFromSQL.fetch()
            try optionalValuesFromRequest.fetch()
            try rowsFromSQL.fetch()
            try rowsFromRequest.fetch()
            try recordsFromSQL.fetch()
            try recordsFromRequest.fetch()
            
            XCTAssertTrue(valuesFromSQL.isEmpty)
            XCTAssertTrue(valuesFromRequest.isEmpty)
            XCTAssertTrue(optionalValuesFromSQL.isEmpty)
            XCTAssertTrue(optionalValuesFromRequest.isEmpty)
            XCTAssertTrue(rowsFromSQL.isEmpty)
            XCTAssertTrue(rowsFromRequest.isEmpty)
            XCTAssertTrue(recordsFromSQL.isEmpty)
            XCTAssertTrue(recordsFromRequest.isEmpty)
            
            XCTAssertEqual(valuesFromSQL.count, 0)
            XCTAssertEqual(valuesFromRequest.count, 0)
            XCTAssertEqual(optionalValuesFromSQL.count, 0)
            XCTAssertEqual(optionalValuesFromRequest.count, 0)
            XCTAssertEqual(rowsFromSQL.count, 0)
            XCTAssertEqual(rowsFromRequest.count, 0)
            XCTAssertEqual(recordsFromSQL.count, 0)
            XCTAssertEqual(recordsFromRequest.count, 0)
            
            XCTAssertEqual(valuesFromSQL.startIndex, 0)
            XCTAssertEqual(valuesFromRequest.startIndex, 0)
            XCTAssertEqual(optionalValuesFromSQL.startIndex, 0)
            XCTAssertEqual(optionalValuesFromRequest.startIndex, 0)
            XCTAssertEqual(rowsFromSQL.startIndex, 0)
            XCTAssertEqual(rowsFromRequest.startIndex, 0)
            XCTAssertEqual(recordsFromSQL.startIndex, 0)
            XCTAssertEqual(recordsFromRequest.startIndex, 0)
            
            XCTAssertEqual(valuesFromSQL.endIndex, 0)
            XCTAssertEqual(valuesFromRequest.endIndex, 0)
            XCTAssertEqual(optionalValuesFromSQL.endIndex, 0)
            XCTAssertEqual(optionalValuesFromRequest.endIndex, 0)
            XCTAssertEqual(rowsFromSQL.endIndex, 0)
            XCTAssertEqual(rowsFromRequest.endIndex, 0)
            XCTAssertEqual(recordsFromSQL.endIndex, 0)
            XCTAssertEqual(recordsFromRequest.endIndex, 0)
        }
    }
    
    func testFetchedCollectionSetRequestThenFetch() {
        assertNoError {
            let dbPool = try makeDatabasePool()
            let sql1 = "SELECT ? AS name, ? AS id UNION ALL SELECT ?, ?"
            let arguments1: StatementArguments = ["a", 1, "b", 2]
            let sqlRequest1 = SQLRequest(sql1, arguments: arguments1)
            
            let valuesFromSQL = try FetchedCollection<String>(dbPool, sql: sql1, arguments: arguments1)
            let valuesFromRequest = try FetchedCollection(dbPool, request: sqlRequest1.bound(to: String.self))
            let optionalValuesFromSQL = try FetchedCollection<String?>(dbPool, sql: sql1, arguments: arguments1)
            let optionalValuesFromRequest = try FetchedCollection(dbPool, request: sqlRequest1.bound(to: Optional<String>.self))
            let rowsFromSQL = try FetchedCollection<Row>(dbPool, sql: sql1, arguments: arguments1)
            let rowsFromRequest = try FetchedCollection(dbPool, request: sqlRequest1.bound(to: Row.self))
            let recordsFromSQL = try FetchedCollection<AnyRowConvertible>(dbPool, sql: sql1, arguments: arguments1)
            let recordsFromRequest = try FetchedCollection(dbPool, request: sqlRequest1.bound(to: AnyRowConvertible.self))
            
            // setRequest
            let sql2 = "SELECT ? AS name, ? AS id UNION ALL SELECT ?, ?"
            let arguments2: StatementArguments = ["c", 3, "d", 4]
            let sqlRequest2 = SQLRequest(sql2, arguments: arguments2)
            
            try valuesFromSQL.setRequest(sql: sql2, arguments: arguments2)
            try valuesFromRequest.setRequest(sqlRequest2.bound(to: String.self))
            try optionalValuesFromSQL.setRequest(sql: sql2, arguments: arguments2)
            try optionalValuesFromRequest.setRequest(sqlRequest2.bound(to: Optional<String>.self))
            try rowsFromSQL.setRequest(sql: sql2, arguments: arguments2)
            try rowsFromRequest.setRequest(sqlRequest2.bound(to: Row.self))
            try recordsFromSQL.setRequest(sql: sql2, arguments: arguments2)
            try recordsFromRequest.setRequest(sqlRequest2.bound(to: AnyRowConvertible.self))
            
            // fetch
            try valuesFromSQL.fetch()
            try valuesFromRequest.fetch()
            try optionalValuesFromSQL.fetch()
            try optionalValuesFromRequest.fetch()
            try rowsFromSQL.fetch()
            try rowsFromRequest.fetch()
            try recordsFromSQL.fetch()
            try recordsFromRequest.fetch()
            
            // collection now contains values from request 2
            XCTAssertEqual(Array(valuesFromSQL), ["c", "d"])
            XCTAssertEqual(Array(valuesFromRequest), ["c", "d"])
            XCTAssertEqual(Array(optionalValuesFromSQL).map { $0! }, ["c", "d"])
            XCTAssertEqual(Array(optionalValuesFromRequest).map { $0! }, ["c", "d"])
            XCTAssertEqual(Array(rowsFromSQL), [["name": "c", "id": 3], ["name": "d", "id": 4]])
            XCTAssertEqual(Array(rowsFromRequest), [["name": "c", "id": 3], ["name": "d", "id": 4]])
            XCTAssertEqual(Array(recordsFromSQL), [AnyRowConvertible(row: ["name": "c", "id": 3]), AnyRowConvertible(row: ["name": "d", "id": 4])])
            XCTAssertEqual(Array(recordsFromRequest), [AnyRowConvertible(row: ["name": "c", "id": 3]), AnyRowConvertible(row: ["name": "d", "id": 4])])
       }
    }
}
