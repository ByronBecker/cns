import APITypes "../../common/api/types";
import Domain "../../common/data/domain";
import DomainTypes "../../common/data/domain/types";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";

module {
  public func register(
    domainRecordsStore: DomainTypes.DomainRecordsStore,
    tld : Text,
    domain : Text,
    principal : Principal,
    records : APITypes.RegistrationRecords
  ) : APITypes.RegisterResult {

    let domainRecords = Option.get(records.records, []);
    // TODO: remove the restriction of acceping exactly one domain record.
    if (domainRecords.size() != 1) {
      return {
        success = false;
        message = ?"Currently exactly one domain record must be specified.";
      };
    };
    let record : DomainTypes.DomainRecord = domainRecords[0];
    let sanitizedDomain = Domain.sanitizeDomain(domain);
    // TODO: sanitize other fields of the domain record(s)

    switch (validateRecord(tld, sanitizedDomain, principal, record)) {
      case (#err(message)) return { success = false; message = ?message };
      case (#ok) {};
    };

    Domain.addRecord(domainRecordsStore, sanitizedDomain, principal, record);

    return {
      success = true;
      message = null;
    };
  };

  // TODO: add more checks: validate domain name and all the fields of the domain record(s).
  func validateRecord(tld : Text, domain : Text, principal : Principal, record : DomainTypes.DomainRecord) : Result.Result<(), Text> {
    if (not Text.endsWith(domain, #text tld)) {
      return #err("Unsupported TLD in domain " # domain # ", expected TLD=" # tld);
    };

    // Disallow someone to register a reverse domain
    let parts = Iter.toArray(Text.split(domain, #char '.'));
    if (parts.size() < 2) return #err("No domain present");
    let secondToLastPart = parts[parts.size() - 2];
    if (secondToLastPart == "reverse") return #err("This domain is reserved");

    // Check that the domain matches the record name
    if (domain != Text.toLower(record.name)) {
      return #err("Inconsistent domain record, record.name: `" # record.name # "` doesn't match domain: " # domain);
    };

    switch (isCompatibleWithDomain(tld, record, principal, domain)) {
      case (#ok) {};
      case (#err(message)) return #err("Incompatible domain record: " # message);
    };

    #ok;
  };

  func isCompatibleWithDomain(tld : Text, record: DomainTypes.DomainRecord, principal : Principal, domain : Text) : Result.Result<(), Text> {
    switch (record.record_type) {
      case ("SID") {
        let expectedEnding = ".subnet" # tld;
        if (not Text.endsWith(domain, #text(expectedEnding))) return #err("Unsupported TLD in domain " # domain # ", expected TLD=" # expectedEnding);
        let parts = Iter.toArray(Text.split(domain, #char '.'));
        // Check that the principal is a valid subnet principal (self-authenticating)
        let domainPrincipal = Principal.fromText(parts[0]);
        if (domainPrincipal != principal) return #err("Domain principal does not match the provided principal");
        if (not Principal.isSelfAuthenticating(principal)) return #err("Invalid subnet principal: " # parts[0]);

        #ok;
      };
      case ("CID") {
        if (not Text.endsWith(domain, #text(tld))) return #err("Unsupported TLD in domain " # domain # ", expected TLD=" # tld);
        // Check that the principal is a valid canister principal (opaque)
        if (not Principal.isCanister(principal)) return #err("Invalid canister principal: " # Principal.toText(principal));

        #ok;
      };

      case _ return #err("Unsupported record type");
    };
  };
}