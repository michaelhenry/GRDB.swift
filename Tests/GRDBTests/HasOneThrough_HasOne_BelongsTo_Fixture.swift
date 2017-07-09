import XCTest
#if GRDBCIPHER
    import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

struct HasOneThrough_HasOne_BelongsTo_Fixture {
    
    // Country <- CountryProfile -> Continent
    struct Country : TableMapping, RowConvertible, Persistable {
        static let databaseTableName = "countries"
        let code: String
        let name: String
        
        init(row: Row) {
            code = row.value(named: "code")
            name = row.value(named: "name")
        }
        
        func encode(to container: inout PersistenceContainer) {
            container["code"] = code
            container["name"] = name
        }
        
        static let optionalProfile = hasOne(optional: CountryProfile.self)
        static let optionalContinent = hasOne(optional: CountryProfile.optionalContinent, through: profile)
        
        static let profile = hasOne(CountryProfile.self)
        static let continent = hasOne(CountryProfile.continent, through: profile)
    }
    
    struct Continent : TableMapping, RowConvertible, Persistable {
        static let databaseTableName = "continents"
        let id: Int64
        let name: String
        
        init(row: Row) {
            id = row.value(named: "id")
            name = row.value(named: "name")
        }
        
        func encode(to container: inout PersistenceContainer) {
            container["id"] = id
            container["name"] = name
        }
    }
    
    struct CountryProfile : TableMapping, RowConvertible, Persistable {
        static let databaseTableName = "countryProfiles"
        let countryCode: String
        let continentId: Int64?
        let currency: String
        
        init(row: Row) {
            countryCode = row.value(named: "countryCode")
            continentId = row.value(named: "continentId")
            currency = row.value(named: "currency")
        }
        
        func encode(to container: inout PersistenceContainer) {
            container["countryCode"] = countryCode
            container["continentId"] = continentId
            container["currency"] = currency
        }
        
        static let optionalContinent = belongsTo(optional: Continent.self)
        static let continent = belongsTo(Continent.self)
    }
    
    
    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("fixtures") { db in
            try db.create(table: "countries") { t in
                t.column("code", .text).primaryKey()
                t.column("name", .text)
            }
            
            try Country(row: ["code": "DE", "name": "Germany"]).insert(db)
            try Country(row: ["code": "FR", "name": "France"]).insert(db)
            try Country(row: ["code": "US", "name": "United States"]).insert(db)
            try Country(row: ["code": "MX", "name": "Mexico"]).insert(db)
            try Country(row: ["code": "AA", "name": "Atlantis"]).insert(db)
            
            try db.create(table: "continents") { t in
                t.column("id", .integer).primaryKey()
                t.column("name", .text)
            }
            
            try Continent(row: ["id": 1, "name": "Europe"]).insert(db)
            try Continent(row: ["id": 2, "name": "America"]).insert(db)
            
            try db.create(table: "countryProfiles") { t in
                t.column("countryCode", .text).references("countries")
                t.column("continentId", .integer).references("continents")
                t.column("currency", .text)
            }
            
            try CountryProfile(row: ["countryCode": "FR", "continentId": 1, "currency": "EUR"]).insert(db)
            try CountryProfile(row: ["countryCode": "DE", "continentId": 1, "currency": "EUR"]).insert(db)
            try CountryProfile(row: ["countryCode": "US", "continentId": 2, "currency": "USD"]).insert(db)
            try CountryProfile(row: ["countryCode": "MX", "continentId": nil, "currency": "MXN"]).insert(db)
        }
        
        return migrator
    }
}
