import Principal "mo:base/Principal";
import Domain "../../common/data/domain";
import APITypes "../../common/api/types";
import Mutate "mutations";
import Query "queries";

actor TldOperator {
  let myTld = ".icp.";
  stable let domainRecordsStore = Domain.initDomainRecordsStore(); 

  public query func lookup(args : APITypes.LookupArgs) : async APITypes.LookupResponse {
    Query.lookup(
      domainRecordsStore,
      myTld,
      args.domain,
      args.recordType
    );
  };

  public shared ({ caller }) func register(args : APITypes.RegisterArgs) : async APITypes.RegisterResult {
    if (not Principal.isController(caller)) {
      return {
        success = false;
        message = ?("Currently only a canister controller can register " # myTld # "-domains, caller: " # Principal.toText(caller));
      };
    };

    Mutate.register(
      domainRecordsStore,
      myTld,
      args.domain,
      args.principal,
      args.records
    );
  };
};
