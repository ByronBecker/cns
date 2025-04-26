import Iter "mo:base/Iter";
import Map "mo:base/Map";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Types "../../common/cns_types";
import APITypes "APITypes";

shared actor class () {
  let icpTld = ".icp.";

  type DomainRecordsMap = Map.Map<Text, Types.DomainRecord>;
  stable let lookupAnswersMap : DomainRecordsMap = Map.empty();
  stable let lookupAuthoritiesMap : DomainRecordsMap = Map.empty();

  func getTld(domain : Text) : Text {
    let parts = Text.split(domain, #char '.');
    let array = Iter.toArray(parts);
    if (array.size() >= 2) {
      return "." # array[array.size() - 2] # ".";
    } else {
      return "..";
    };
  };

  public shared query func lookup(domain : Text, recordType : Text) : async APITypes.LookupResponse {
    var answers : [Types.DomainRecord] = [];
    var authorities : [Types.DomainRecord] = [];

    let domainLowercase : Text = Text.toLower(domain);
    if (Text.endsWith(domainLowercase, #text icpTld)) {
      let tld = getTld(domainLowercase);
      switch (Text.toUpper(recordType)) {
        case ("NC") {
          let maybeRecord : ?Types.DomainRecord = Map.get(lookupAnswersMap, Text.compare, tld);
          answers := switch maybeRecord {
            case null { [] };
            case (?record) { [record] };
          };
        };
        case _ {
          let maybeRecord : ?Types.DomainRecord = Map.get(lookupAuthoritiesMap, Text.compare, tld);
          authorities := switch maybeRecord {
            case null { [] };
            case (?record) { [record] };
          };
        };
      };
    };

    {
      answers = answers;
      additionals = [];
      authorities = authorities;
    };
  };

  public shared ({ caller }) func register(domain : Text, records : Types.RegistrationRecords) : async APITypes.RegisterResult {
    if (not Principal.isController(caller)) {
      return {
        success = false;
        message = ?("Currently only a canister controller can register new TLD-operators, caller: " # Principal.toText(caller));
      };
    };
    let domainLowercase : Text = Text.toLower(domain);
    let tld = getTld(domainLowercase);
    if (tld != domainLowercase) {
      return {
        success = false;
        message = ?("The given domain " # domain # " is not a TLD, its TLD is " # tld);
      };
    };
    if (tld != icpTld) {
      return {
        success = false;
        message = ?("Currently only " # icpTld # "-TLD is supported; requested TLD: " # domain);
      };
    };
    let domainRecords = Option.get(records.records, []);
    // TODO: remove the restriction of acceping exactly one domain record.
    if (domainRecords.size() != 1) {
      return {
        success = false;
        message = ?"Currently exactly one domain record must be specified.";
      };
    };
    let record : Types.DomainRecord = domainRecords[0];
    if (tld != (Text.toLower(record.name))) {
      return {
        success = false;
        message = ?("Inconsistent domain record, record.name: `" # record.name # "` doesn't match TLD: " # tld);
      };
    };
    // TODO: add more checks: validate domain name and all the fields of the domain record(s).

    switch (Text.toUpper(record.record_type)) {
      case ("NC") {
        Map.add(lookupAnswersMap, Text.compare, tld, record);
        Map.add(lookupAuthoritiesMap, Text.compare, tld, record);
        return {
          success = true;
          message = null;
        };
      };
      case _ {
        return {
          success = false;
          message = ?("Unsupported record_type: `" # record.record_type # "`, expected 'NC'");
        };
      };
    };
  };
};
