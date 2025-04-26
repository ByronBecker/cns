import Map "mo:base/Map";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import StableBuffer "mo:stablebuffer/StableBuffer";
import { trimWhitespace; isAlphaNumericOr } "../../sanitize";
import Types "types";

module {
  public func initDomainRecordsStore() : Types.DomainRecordsStore {
    {
      domainToRecordsMap = Map.empty<Types.Domain, Types.DomainRecordWithPrincipals>();
      principalToDomainIndex = Map.empty<Principal, Types.Domain>();
    }
  };

  // returns the sanitized domain name
  // if invalid, returns the empty string
  public func sanitizeDomain(domain : Text) : Text {
    // size check
    if (Text.size(domain) > 40) return "";
    // trim whitespace
    let trimmed = trimWhitespace(domain);
    // character check
    for (char in trimmed.chars()) {
      if (not isAlphaNumericOr(
        char,
        func(c: Char) : Bool = c == '-' or c == '.',
      )) return ""; 
    };
    // domain name must start and end with an alphanumeric character
    if (
      Text.startsWith(trimmed, #char('-')) or
      Text.endsWith(trimmed, #char('-')) or
      Text.startsWith(trimmed, #char('.')) or
      Text.endsWith(trimmed, #char('.'))
    ) return "";

    // Lowercase the domain name
    Text.toLower(trimmed);
  };

  public func addRecord(
    { domainToRecordsMap; principalToDomainIndex }: Types.DomainRecordsStore,
    domain : Types.Domain,
    principal : Principal,
    record : Types.DomainRecord
  ) : () {
    // add main entry
    addToDomainRecordsMap(domainToRecordsMap, domain, record, principal);
    // add to domain to principal index
    Map.add(principalToDomainIndex, Principal.compare, principal, domain);
  };

  public func removePrincipalDomainLink(
    { domainToRecordsMap; principalToDomainIndex }: Types.DomainRecordsStore,
    principal : Principal,
    domain : Types.Domain
  ) : () {
    // remove from the main domain to records map
    removePrincipalFromDomainRecordsMap(domainToRecordsMap, domain, principal);
    // remove from the principal to domain index
    Map.remove(principalToDomainIndex, Principal.compare, principal);
  };

  public func getRecordByDomain(
    domainToRecordsMap : Types.DomainRecordsMap,
    domain : Types.Domain
  ) : ?Types.DomainRecord {
    switch(Map.get(domainToRecordsMap, Text.compare, domain)) {
      case null { null };
      case (?{ record }) ?record;
    };
  };

  public func getRecordByPrincipal(
    { domainToRecordsMap; principalToDomainIndex } : Types.DomainRecordsStore,
    principal : Principal
  ) : ?Types.DomainRecord {
    switch (Map.get(principalToDomainIndex, Principal.compare, principal)) {
      case null { null };
      case (?domain) { getRecordByDomain(domainToRecordsMap, domain) };
    }
  };

  public func isRecordTypeSupported(recordType : Text) : Bool {
    let recordTypeUpper = Text.toUpper(recordType);

    recordTypeUpper == "CID" or
    recordTypeUpper == "SID"
  };

  func addToDomainRecordsMap(
    domainToRecordsMap : Types.DomainRecordsMap,
    domain : Types.Domain,
    record : Types.DomainRecord,
    principal : Principal
  ) : () {
    let domainPrincipals = switch (Map.get(domainToRecordsMap, Text.compare, domain)) {
      case null { StableBuffer.init<Principal>() };
      case (?existingRecord) { existingRecord.principals };
    };
    // Only add the principal if it is not already in the list
    if (not StableBuffer.contains(domainPrincipals, principal, Principal.equal)) {
      StableBuffer.add(domainPrincipals, principal);
    };
    Map.add(
      domainToRecordsMap,
      Text.compare,
      domain,
      {
        record;
        principals = domainPrincipals;
      }
    );
  };

  func removePrincipalFromDomainRecordsMap(
    domainToRecordsMap : Types.DomainRecordsMap,
    domain : Types.Domain,
    principal : Principal
  ) : () {
    let principals = switch (Map.get(domainToRecordsMap, Text.compare, domain)) {
      case null return; 
      case (?existingRecord) { existingRecord.principals };
    };

    switch(StableBuffer.indexOf(principal, principals, Principal.equal)) {
      case null return;
      case (?deleteIndex) { ignore StableBuffer.remove(principals, deleteIndex) };
    };

    // If the existing record has no principals left, remove the record
    if (StableBuffer.isEmpty(principals)) {
      Map.remove(domainToRecordsMap, Text.compare, domain);
    };
  };
}