GRDB Associations
=================

> [**:fire: EXPERIMENTAL**](http://github.com/groue/GRDB.swift#what-are-experimental-features): GRDB associations are young, and not stabilized yet. To help them becoming stable, [your feedback](https://github.com/groue/GRDB.swift/issues) is greatly appreciated.

**An association is a connection between two [Record](http://github.com/groue/GRDB.swift#records) types.** It helps your code perform common operations in an easier way.

For example, consider an application that defines two record types for authors and books. Each author can have many books:

```swift
class Author: Record { ... }
class Book: Record { ... }
```

Without associations, loading all authors with all their books would look like:

```swift
let allAuthorsWithTheirBooks = try dbQueue.inDatabase { db in
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

class Book: Record {
    static let author = belongsTo(Author.self)
    ...
}
```

After associations have been declared, loading all authors with their books is easier:

```swift
let allAuthorsWithTheirBooks = try dbQueue.inDatabase { db in
    return Author.including(Author.books).fetchAll(db)
}
```

Associations bring simpler APIs for a lot more operations. We'll introduce below the various kinds of associations, and provide the reference to their methods and options.


## The Types of Associations

GRDB handles eight types of associations:

- [BelongsTo](#belongsto)
- [BelongsToOptional](#belongstooptional)
- [HasMany](#hasmany)
- [HasManyThrough](#hasmanythrough)
- [HasOne](#hasone)
- [HasOneOptional](#hasoneoptional)
- [HasOneThrough](#hasonethrough)
- [HasOneOptionalThrough](#hasoneoptionalthrough)

An association declares a link from a record type to another, as in "one book *belongs to* its author". It instructs GRDB to use the primary and foreign keys declared in the database as support for Swift methods.

Each one of the eight types of associations is appropriate for a particular database situation.


### BelongsTo

The *BelongsTo* association sets up a one-to-one connection from a record type to another record type, such as each instance of the declaring record "belongs to" an instance of the other record.

For example, if your application includes authors and books, and each book is assigned exactly one author, you'd declare the association this way:

```swift
class Author: Record {
    ...
}

class Book: Record {
    static let author = belongsTo(Author.self)
    ...
}
```

A book **belongs to** its author:

![BelongsToSchema](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/BelongsToSchema.svg)

¹ `authorId` is a *foreign key* to the `authors` table. It is *not null* to enforce the presence of a book's author.

The matching [migration](http://github.com/groue/GRDB.swift#migrations) would look like:

```swift
migrator.registerMigration("BooksAndAuthors") { db in
    try db.create(table: "authors") { t in
        t.column("id", .integer).primaryKey()
        t.column("name", .text)
    }
    try db.create(table: "books") { t in
        t.column("id", .integer).primaryKey()
        t.column("authorId", .integer)
            .notNull()
            .references("authors", onDelete: .cascade)
        t.column("title", .text)
    }
}
```


### BelongsToOptional

The *BelongsToOptional* association also sets up a one-to-one connection from a record type to another record type, such as each instance of the declaring record "belongs to" an instance of the other record. Unlike the *BelongsTo* association, the associated record is optional.

For example, if your application includes authors and books, and each book is assigned zero or one author, not more, you'd declare the association this way:

```swift
class Author: Record {
    ...
}

class Book: Record {
    static let author = belongsTo(optional: Author.self)
    ...
}
```

A book **belongs to** its **optional** author:

![BelongsToSchema](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/BelongsToSchema.svg)

¹ `authorId` is a *foreign key* to the `authors` table. It can be null in order to allow anonymously published books.

The matching [migration](http://github.com/groue/GRDB.swift#migrations) would look like:

```swift
migrator.registerMigration("BooksAndAuthors") { db in
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

The *HasOne* association also sets up a one-to-one connection from a record type to another record type, but with different semantics, and underlying database schema. It it usually used when an entity has been denormalized into two database tables.

For example, if your application includes countries and their demographic profiles, and each country has exactly one demographic profile, you'd declare the association this way:

```swift
class Country: Record {
    static let profile = hasOne(DemographicProfile.self)
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
migrator.registerMigration("BooksAndAuthors") { db in
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


### HasOneOptional

The *HasOneOptional* association also sets up a one-to-one connection from a record type to another record type. Unlike the *HasOne* association, the associated record is optional.

For example, if your application includes countries and their demographic profiles, and each country has zero or one demographic profile, you'd declare the association this way:

```swift
class Country: Record {
    static let profile = hasOne(optional: DemographicProfile.self)
    ...
}

class DemographicProfile: Record {
    ...
}
```

A country **has one optional** demographic profile:

![HasOneSchema](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/HasOneSchema.svg)

¹ `countryCode` is a *foreign key* to the `countries` table. It is *uniquely indexed* to guarantee the unicity of a country's profile.

The matching [migration](http://github.com/groue/GRDB.swift#migrations) would look like:

```swift
migrator.registerMigration("BooksAndAuthors") { db in
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
migrator.registerMigration("BooksAndAuthors") { db in
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

