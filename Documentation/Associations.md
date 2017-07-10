GRDB Associations
=================

> [**:fire: EXPERIMENTAL**](http://github.com/groue/GRDB.swift#what-are-experimental-features): GRDB associations are young, and not stabilized yet. To help them becoming stable, [your feedback](https://github.com/groue/GRDB.swift/issues) is greatly appreciated.

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

After associations have been declared, loading books is much easier:

```swift
// All books written by an author:
let author = ...
let books = try dbQueue.inDatabase { db in
    return try author.fetchAll(Author.books)
}

// All authors with their books:
let allAuthorsWithTheirBooks: [(Author, [Book])] = try dbQueue.inDatabase { db in
    return Author.including(Author.books).fetchAll(db)
}
```

Associations bring simpler APIs for a lot more operations. We'll introduce below the various kinds of associations, and provide the reference to their methods and options.


## The Types of Associations

GRDB handles eight types of associations:

- BelongsTo, BelongsToOptional
- HasMany
- HasManyThrough
- HasOne, HasOneOptional
- HasOneThrough, HasOneOptionalThrough

An association declares a link from a record type to another, as in "one book *belongs to* its author". It instructs GRDB to use the primary and foreign keys declared in the database as support for Swift methods.

Each one of the eight types of associations is appropriate for a particular database situation.


### BelongsTo and BelongsToOptional

The *BelongsTo* and *BelongsToOptional* associations set up a one-to-one connection from a record type to another record type, such as each instance of the declaring record "belongs to" an instance of the other record.

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

![BelongsToSchema](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/BelongsToSchema.svg)

¹ `authorId` is a *foreign key* to the `authors` table. When it is *not null* the presence of a book's author is enforced.

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
            .notNull() // for BelongsTo association
            .references("authors", onDelete: .cascade)
        t.column("title", .text)
    }
}
```


### HasOne and HasOneOptional

The *HasOne* and *HasOneOptional* associations also set up a one-to-one connection from a record type to another record type, but with different semantics, and underlying database schema. They are usually used when an entity has been denormalized into two database tables.

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

![HasOneSchema](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/HasOneSchema.svg)

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

The *HasMany* association indicates a one-to-many connection between two record types, such as each instance of the declaring record "has many" instances of the other record. You'll often find this association on the other side of a *BelongsTo* or *BelongsToOptional* association.

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

![HasManySchema](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/HasManySchema.svg)

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

![HasManyThroughSchema](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/HasManyThroughSchema.svg)

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


### HasOneThrough and HasOneOptionalThrough

The *HasOneThrough* and *HasOneOptionalThrough* associations set up a one-to-one connection between two record types, *through* a third record. You declare this association by linking two other one-to-one associations together.

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

![HasOneThroughSchema](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/HasOneThroughSchema.svg)

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
