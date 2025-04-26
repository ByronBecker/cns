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

    switch (validateRecord(tld, sanitizedDomain, record)) {
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
  func validateRecord(tld : Text, domain : Text, record : DomainTypes.DomainRecord) : Result.Result<(), Text> {
    if (not Text.endsWith(domain, #text tld)) {
      return #err("Unsupported TLD in domain " # domain # ", expected TLD=" # tld);
    };

    if (domain != Text.toLower(record.name)) {
      return #err("Inconsistent domain record, record.name: `" # record.name # "` doesn't match domain: " # domain);
    };

    switch (isCompatibleWithDomain(record, domain)) {
      case (#ok) {};
      case (#err(message)) return #err("Incompatible domain record: " # message);
    };

    #ok;
  };

  func isCompatibleWithDomain(record: DomainTypes.DomainRecord, domain : Text) : Result.Result<(), Text> {
    switch (record.record_type) {
      case ("SID") {
        if (not Text.endsWith(domain, #text ".subnet.icp")) return #err("Unsupported TLD in domain " # domain # ", expected TLD=.subnet.icp");
        let parts = Iter.toArray(Text.split(domain, #char '.'));
        // Check that the principal is a valid subnet principal (self-authenticating)
        let principal = Principal.fromText(parts[0]);
        if (not Principal.isSelfAuthenticating(principal)) return #err("Invalid subnet principal: " # parts[0]);

        #ok;
      };

      case _ return #err("Unsupported record type");
    };
  };
}