GRDB Associations
=================

> [**:fire: EXPERIMENTAL**](http://github.com/groue/GRDB.swift#what-are-experimental-features): GRDB associations are young, and not stabilized yet. To help them becoming stable, [your feedback](https://github.com/groue/GRDB.swift/issues) is greatly appreciated.


## Chapters

- [Introduction](#introduction)
- [The Types of Associations](#the-types-of-associations)
    - [BelongsTo](#belongsto)
    - [HasMany](#hasmany)
    - [HasManyThrough](#hasmanythrough)
    - [HasOne](#hasone)
    - [HasOneThrough](#hasonethrough)
    - [Choosing Between BelongsTo and HasOne](#choosing-between-belongsto-and-hasone)
    - [Self Joins](#self-joins)
- [Associations and the Database Schema](#associations-and-the-database-schema)


## Introduction

**An association is a connection between two [Record](http://github.com/groue/GRDB.swift#records) types.** It helps your code perform common operations in an easier way.

For example, consider an application that defines two record types for authors and books. Each author can have many books:

```swift
class Author: Record { ... }
class Book: Record { ... }
```

Without associations, loading books from authors would look like:

```swift
// All books written by an author:
let author = ...
let books = try dbQueue.inDatabase { db in
    return try Book
        .filter(Book.Columns.authorId == author.id)
        .fetchAll(db)
}

// All authors with their books:
let allAuthorsWithTheirBooks: [(Author, [Book])] = try dbQueue.inDatabase { db in
    let authors = try Author.fetchAll(db)
    return try authors.map { author in
        let books = try Book
            .filter(Book.Columns.authorId == author.id)
            .fetchAll(db)
        return (author, books)
    }
}
```

With associations, this code can be streamlined. Associations are declared in the record types:

```swift
class Author: Record {
    static let books = hasMany(Book.self)
    ...
}
```

After the `Author.books` association has been declared, loading books is much easier:

```swift
// All books written by an author:
let author = ...
let books = try dbQueue.inDatabase { db in
    return try author.fetchAll(db, Author.books)
}

// All authors with their books:
let allAuthorsWithTheirBooks: [(Author, [Book])] = try dbQueue.inDatabase { db in
    return Author.including(Author.books).fetchAll(db)
}
```

Associations bring simpler APIs for a lot more operations. We'll introduce below the various kinds of associations, and then provide the reference to their methods and options.


## The Types of Associations

GRDB handles five types of associations:

- BelongsTo
- HasMany
- HasManyThrough
- HasOne
- HasOneThrough

An association declares a link from a record type to another, as in "one book *belongs to* its author". It instructs GRDB to use the primary and foreign keys declared in the database as support for Swift methods.

Each one of the eight types of associations is appropriate for a particular database situation.


### BelongsTo

The *BelongsTo* association sets up a one-to-one connection from a record type to another record type, such as each instance of the declaring record "belongs to" an instance of the other record.

For example, if your application includes authors and books, and each book is assigned its author, you'd declare the association this way:

```swift
class Book: Record {
    // When the database always has an author for a book:
    static let author = belongsTo(Author.self)
    
    // When author can be missing:
    static let author = belongsTo(optional: Author.self)
    ...
}

class Author: Record {
    ...
}
```

A book **belongs to** its author:

![BelongsToDatabase](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/BelongsToDatabase.svg)

¹ `authorId` is a *foreign key* to the `authors` table.

The matching [migration](http://github.com/groue/GRDB.swift#migrations) would look like:

```swift
migrator.registerMigration("Books and Authors") { db in
    try db.create(table: "authors") { t in
        t.column("id", .integer).primaryKey()
        t.column("name", .text)
    }
    try db.create(table: "books") { t in
        t.column("id", .integer).primaryKey()
        t.column("authorId", .integer)
            .references("authors", onDelete: .cascade)
        t.column("title", .text)
    }
}
```


### HasOne

The *HasOne* association also sets up a one-to-one connection from a record type to another record type, but with different semantics, and underlying database schema. It is usually used when an entity has been denormalized into two database tables.

For example, if your application includes countries and their demographic profiles, and each country has its demographic profile, you'd declare the association this way:

```swift
class Country: Record {
    // When the database always has a demographic profile for a country:
    static let profile = hasOne(DemographicProfile.self)
    
    // When demographic profile can be missing:
    static let profile = hasOne(optional: DemographicProfile.self)
    ...
}

class DemographicProfile: Record {
    ...
}
```

A country **has one** demographic profile:

![HasOneDatabase](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/HasOneDatabase.svg)

¹ `countryCode` is a *foreign key* to the `countries` table. It is *uniquely indexed* to guarantee the unicity of a country's profile.

The matching [migration](http://github.com/groue/GRDB.swift#migrations) would look like:

```swift
migrator.registerMigration("Countries and DemographicProfiles") { db in
    try db.create(table: "countries") { t in
        t.column("code", .text).primaryKey()
        t.column("name", .text)
    }
    try db.create(table: "demographicProfiles") { t in
        t.column("id", .integer).primaryKey()
        t.column("countryCode", .text)
            .unique()
            .references("countries", onDelete: .cascade)
        t.column("population", .integer)
        t.column("density", .double)
    }
}
```


### HasMany

The *HasMany* association indicates a one-to-many connection between two record types, such as each instance of the declaring record "has many" instances of the other record. You'll often find this association on the other side of a *BelongsTo* association.

For example, if your application includes authors and books, and each author is assigned zero or more books, you'd declare the association this way:

```swift
class Author: Record {
    static let books = hasMany(Book.self)
}

class Book: Record {
    ...
}
```

An author **has many** books:

![HasManyDatabase](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/HasManyDatabase.svg)

¹ `authorId` is a *foreign key* to the `authors` table. It is *indexed* to ease the selection of books belonging to a specific author.

The matching [migration](http://github.com/groue/GRDB.swift#migrations) would look like:

```swift
migrator.registerMigration("Books and Authors") { db in
    try db.create(table: "authors") { t in
        t.column("id", .integer).primaryKey()
        t.column("name", .text)
    }
    try db.create(table: "books") { t in
        t.column("id", .integer).primaryKey()
        t.column("authorId", .integer)
            .indexed()
            .references("authors", onDelete: .cascade)
        t.column("title", .text)
    }
}
```


### HasManyThrough

The *HasManyThrough* association sets up a one-to-many connection between two record types, *through* a third record. You declare this association by linking two other associations together.

For example, consider an application that includes countries, passports, and citizens. You'd declare a *HasManyThrough* association between countries and citizens by linking a *HasMany* association from countries to passports, and a *BelongsTo* association from passports to citizens:

```swift
class Country : Record {
    static let passports = hasMany(Passport.self)
    static let citizens = hasMany(Passport.citizen, through: passports)
    ...
}

class Passport : Record {
    static let citizen = belongsTo(Citizen.self)
    ...
}

class Citizen : Record {
    ...
}
```

A country **has many** citizens **through** passports:

![HasManyThroughDatabase](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/HasManyThroughDatabase.svg)

¹ `countryCode` is a *foreign key* to the `countries` table.

² `citizenId` is a *foreign key* to the `citizens` table.

The matching [migration](http://github.com/groue/GRDB.swift#migrations) would look like:

```swift
migrator.registerMigration("Countries, Passports, and Citizens") { db in
    try db.create(table: "countries") { t in
        t.column("code", .text).primaryKey()
        t.column("name", .text)
    }
    try db.create(table: "citizens") { t in
        t.column("id", .integer).primaryKey()
        t.column("name", .text)
    }
    try db.create(table: "passports") { t in
        t.column("countryCode", .text)
            .notNull()
            .references("countries", onDelete: .cascade)
        t.column("citizenId", .text)
            .notNull()
            .references("citizens", onDelete: .cascade)
        t.primaryKey(["countryCode", "citizenId"])
        t.column("issueDate", .date)
    }
}
```

> :point_up: **Note**: the example above defines a *HasManyThrough* association by linking a *HasMany* association and a *BelongsTo* association. In general, any two associations that share the same intermediate type can be used to define a *HasManyThrough* association.


### HasOneThrough

The *HasOneThrough* association sets up a one-to-one connection between two record types, *through* a third record. You declare this association by linking two other one-to-one associations together.

For example, consider an application that includes books, libraries, and addresses. You'd declare that each book has its return address by linking a *BelongsTo* association from books to libraries, and a *HasOne* association from libraries to addresses:

```swift
class Book : Record {
    static let library = belongsTo(Library.self)
    static let returnAddress = hasOne(Library.address, through: library)
    ...
}

class Library : Record {
    static let address = hasOne(Address.self)
    ...
}

class Address : Record {
    ...
}
```

A book **has one** return address **through** its library:

![HasOneThroughDatabase](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/HasOneThroughDatabase.svg)

¹ `libraryId` is a *foreign key* to the `libraries` table.

² `libraryId` is both the *primary key* of the `addresses` table, and a *foreign key* to the `libraries` table.

The matching [migration](http://github.com/groue/GRDB.swift#migrations) would look like:

```swift
migrator.registerMigration("Books, Libraries, and Addresses") { db in
    try db.create(table: "libraries") { t in
        t.column("id", .integer).primaryKey()
        t.column("name", .text)
    }
    try db.create(table: "books") { t in
        t.column("id", .integer).primaryKey()
        t.column("libraryId", .integer)
            .notNull()
            .references("libraries", onDelete: .cascade)
        t.column("title", .text).primaryKey()
    }
    try db.create(table: "addresses") { t in
        t.column("libraryId", .integer)
            .primaryKey()
            .references("libraries", onDelete: .cascade)
        t.column("street", .text)
        t.column("city", .text)
    }
}
```

> :point_up: **Note**: the example above defines a *HasOneThrough* association by linking a *BelongsTo* association and a *HasOne* association. In general, any two non-optional one-to-one associations that share the same intermediate type can be used to define a *HasOneThrough* association. When one or both of the linked associations is optional, you build a *HasOneOptionalThrough* association.


### Choosing Between BelongsTo and HasOne

When you want to set up a one-to-one relationship between two record types, you'll need to add a *BelongsTo* association to one, and a *HasOne* association to the other. How do you know which is which?

The distinction is in where you place the database foreign key. The record that points to the other one has the *BelongsTo* association. The other record has the *HasOne* association:

A demographic profile **belongs to** a country, and a country **has one** demographic profile:

![HasOneDatabase](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/HasOneDatabase.svg)

```swift
class Country: Record {
    static let profile = hasOne(DemographicProfile.self)
    ...
}

class DemographicProfile: Record {
    static let country = belongsTo(DemographicProfile.self)
    ...
}
```


### Self Joins

In designing a data model, you will sometimes find a model that should have a relation to itself. For example, you may want to store all employees in a single database model, but be able to trace relationships such as between manager and subordinates. This situation can be modeled with self-joining associations:

```swift
class Employee: Record {
    static let manager = belongsTo(optional: Employee.self)
    static let subordinates = hasMany(Employee.self)
    ...
}
```

![SelfJoinSchema](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/SelfJoinSchema.svg)

The matching [migration](http://github.com/groue/GRDB.swift#migrations) would look like:

```swift
migrator.registerMigration("Employees") { db in
    try db.create(table: "employees") { t in
        t.column("id", .integer).primaryKey()
        t.column("managerId", .integer).references("employees")
        t.column("name", .text)
    }
}
```


## Associations and the Database Schema

In all examples above, we have defined associations without giving the name of any database column:

```swift
class Author: Record {
    static let books = hasMany(Book.self)
}

class Book: Record {
    static let author = belongsTo(Author.self)
}
```

This concise definition of association is possible when the database schema defines the primary and foreign keys that support the association. For example,  in the migration below, the `authors` table has a primary key, and the `books` table has a foreign key:

```swift
migrator.registerMigration("Books and Authors") { db in
    try db.create(table: "authors") { t in
        t.column("id", .integer).primaryKey() // primary key
        t.column("name", .text)
    }
    try db.create(table: "books") { t in
        t.column("id", .integer).primaryKey()
        t.column("authorId", .integer)        // foreign key
            .notNull()
            .indexed()
            .references("authors", onDelete: .cascade)
        t.column("title", .text)
    }
}
```

Sometimes the database schema is ambiguous. This happens when a table defines several foreign keys to another table. This also happens when the schema is loose, and does not define any foreign or primary key at all.

In this case, you must help GRDB finding the supporting columns:

- Either by providing the column that points to the other table. This works if the target table has a primary key:

    ```swift
    class Author: Record {
        static let books = hasMany(Book.self, from: "authorId")
    }

    class Book: Record {
        static let author = belongsTo(Author.self, from: "authorId")
    }
    ```

- Or by providing the full definition of the missing foreign key. This will always work, even if the target table has no primary key:

    ```swift
    class Author: Record {
        static let books = hasMany(Book.self, from: ["authorId"], to: "[id"])
    }

    class Book: Record {
        static let author = belongsTo(Author.self, from: ["authorId"], to: ["id"])
    }
    ```

- [ ] **TODO**: Let user use the `Column` type
- [ ] **TODO**: Allow or forbid for good compound primary keys. If forbidden, there is no point providing arrays to the complete foreign key definition.

