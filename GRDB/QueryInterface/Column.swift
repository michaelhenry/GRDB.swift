/// The protocol for columns in the database
///
/// See https://github.com/groue/GRDB.swift#the-query-interface
public protocol ColumnProtocol : SQLExpression {
    /// The name of the column
    var name: String { get }
}

extension ColumnProtocol {
    /// This function is an implementation detail of the query interface.
    /// Do not use it directly.
    ///
    /// See https://github.com/groue/GRDB.swift/#the-query-interface
    ///
    /// # Low Level Query Interface
    ///
    /// See SQLExpression.expressionSQL(_:arguments:)
    public func expressionSQL(_ arguments: inout StatementArguments?) -> String {
        return name.quotedDatabaseIdentifier
    }
}

/// A column in the database
///
/// See https://github.com/groue/GRDB.swift#the-query-interface
public struct Column : ColumnProtocol {
    /// The hidden rowID column
    public static let rowID = Column("rowid")
    
    /// The name of the column
    public let name: String
    
    /// Creates a column given its name.
    public init(_ name: String) {
        self.name = name
    }
}

extension RawRepresentable where Self: ColumnProtocol, Self.RawValue == String {
    /// TODO
    public var name: String {
        return rawValue
    }
}
