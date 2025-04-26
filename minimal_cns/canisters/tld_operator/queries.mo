import APITypes "../../common/api/types";
import DomainTypes "../../common/data/domain/types";
import Text "mo:base/Text";
import Domain "../../common/data/domain";

module {
  public func lookup(
    { domainToRecordsMap } : DomainTypes.DomainRecordsStore, 
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

    let answers = switch(Domain.getRecordByDomain(domainToRecordsMap, sanitizedDomain)) {
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