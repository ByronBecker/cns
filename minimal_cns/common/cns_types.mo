import Text "mo:base/Text";
import Principal "mo:base/Principal";
import List "mo:base/List";

module {
  public type RecordName = Text;
  /// DomainRecord represents a zone record item.
  public type DomainRecord = {
    /// The domain name, e.g. "mydomain.tld.", the name is required for all operations and must
    /// end with a dot (.). Names have well defined size limits and must have the parts between
    /// the dots or commonly called as labels with equal or less then 63 bytes and the entire
    /// name must be under 255 bytes.
    ///
    /// Names are encoded in ascii and are case insensitive, but the canonical form is lowercase.
    name : RecordName;
    /// The record type refers to the classification or category of a specific record within the
    /// system, e.g. "CID", "A", "CNAME", "TXT", "MX", "AAAA", "NC", "NS", "DNSKEY", "NSEC".
    ///
    /// Also, "ANY" is a reserved type that can only be used in lookups to retrieve all records of a domain.
    ///
    /// Record types can have maximum of 12 bytes, are encoded in ascii and are case insensitive,
    record_type : Text;
    /// The Time to Live (TTL) is a parameter in a record that specifies the amount of time for
    /// which the record should be cached before being refreshed from the authoritative naming canister.
    ///
    /// This value must be set in seconds and the minimum value is 0 seconds, which means not cached.
    /// Common values for TTL include 3600 seconds (1 hour), 86400 seconds (24 hours), or other intervals
    /// based on specific needs.
    ttl : Nat;
    /// The record data in a domain record refers to the specific information associated with that record type.
    /// Format of the data depends on the type of record to fit its purpose, but it must not exceed 2550 bytes.
    data : Text;
  };
  public type DomainLookup = {
    // The list of answers that match the lookup, the answers section is the most important part of
    // the lookup result as it contains the actual data that the client is looking for.
    answers : List.List<DomainRecord>;
    // Additionals are records that are not a direct match with the lookuped up record type but facilitate the process,
    // e.g. returning the CID records from a NC lookup to prevent the client from having to perform another lookup.
    additionals : List.List<DomainRecord>;
    // Authorities contains records that point toward the authoritative naming canister/server for the domain.
    authorities : List.List<DomainRecord>;
  };

  public type DomainLookupShared = {
    answers : [DomainRecord];
    additionals : [DomainRecord];
    authorities : [DomainRecord];
  };

  public type OperationResult = {
    success : Bool;
    message : ?Text;
  };

  public type RegisterResult = OperationResult;

  public type RegistrationControllerRole = {
    #registrar;
    #registrant;
    #technical;
    #administrative;
  };

  public type RegistrationController = {
    principal : Principal;
    roles : [RegistrationControllerRole];
  };

  /*
  // Types related to domain registration, but not used by `register`-endpoint.
  type DomainRegistrationStatus = { #active; #inactive; #transfer_prohibited };
  type RegistrationEventAction = {
    #registration;
    #locked;
    #unlocked;
    #expiration;
    #reregistration;
    #transfer;
  };

  type RegistrationEvent = {
    action : RegistrationEventAction;
    date : Text;
  };
  type DomainRegistrationData = {
    name : Text;
    status : [DomainRegistrationStatus];
    events : [RegistrationEvent];
    entities : [RegistrationController];
    name_canister : ?Principal;
  };

  type RegistrationDataResult = {
    certificate : Blob;
    data : DomainRegistrationData;
  };
  */

  public type RegistrationRecords = {
    controller : [RegistrationController];
    records : ?[DomainRecord];
  };
};
