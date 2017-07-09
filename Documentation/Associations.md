GRDB Associations
=================

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


## The Types of Associations

GRDB handles eight types of associations:

- BelongsTo
- BelongsToOptional
- HasMany
- HasManyThrough
- HasOne
- HasOneOptional
- HasOneThrough
- HasOneOptionalThrough
