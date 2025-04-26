import APITypes "../../common/api/types";
import DomainTypes "../../common/data/domain/types";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Domain "../../common/data/domain";

module {
  public func lookup(
    domainRecordsStore : DomainTypes.DomainRecordsStore,
    tld : Text,
    domain : Text,
    recordType : Text,
  ) : APITypes.LookupResponse {
    // sanitize the input domain
    let sanitizedDomain = Domain.sanitizeDomain(domain);

    // Ensure the lookup domain matches the TLD and the record type is supported.
    if (
      not Text.endsWith(sanitizedDomain, #text tld) or
      Domain.isRecordTypeSupported(recordType)
    ) {
      return { answers = []; additionals = []; authorities = [] };
    };

    if (Text.toUpper(recordType) == "PTR") return reverseLookup(domainRecordsStore, sanitizedDomain);

    let answers = switch(Domain.getRecordByDomain(domainRecordsStore.domainToRecordsMap, sanitizedDomain)) {
      case null { [] };
      case (?record) {
        if (Text.toUpper(record.record_type) != Text.toUpper(recordType)) { [] }
        else { [record] }
      };
    };

    {
      answers;
      additionals = [];
      authorities = [];
    };
  };

  // Reverse lookups have the format <principal>.reverse.<tld>
  // In this case, we expect the <principal> to be a valid principal.
  public func reverseLookup(
    domainRecordsStore: DomainTypes.DomainRecordsStore,
    domain : Text,
  ) : APITypes.LookupResponse {

    // split the domain into parts, based on "."
    let parts = Iter.toArray(Text.split(domain, #char '.'));
    // expect there to be exactly 3 parts: <principal>, reverse, <tld>
    // TODO: Is this assumption correct?
    if (parts.size() != 3) {
      return { answers = []; additionals = []; authorities = [] };
    };

    let principalText = parts[0];
    // check if the first part is a valid principal - will trap if not
    // TODO: perform this check without trapping
    let principal = Principal.fromText(principalText);

    // check if the second part is "reverse"
    if (parts[1] != "reverse") {
      return { answers = []; additionals = []; authorities = [] };
    };

    // look up the domain record by the principal

    let answers = switch(Domain.getRecordByPrincipal(domainRecordsStore, principal)) {
      case null { [] };
      case (?record) { [record] };
    };

    {
      answers;
      additionals = [];
      authorities = [];
    };
  };
}