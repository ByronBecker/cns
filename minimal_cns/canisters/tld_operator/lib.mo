import APITypes "api_types";
import Map "mo:base/Map";
import Domain "../../common/data/domain";
import Metrics "../../common/metrics";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import { trap } "mo:base/Runtime";
import Text "mo:base/Text";
import Mutations "mutations";
import Queries "queries";

actor TldOperator {
  let myTld = ".icp.";
  stable let domainRecordsStore = Domain.initDomainRecordsStore();

  stable var metricsStore : Metrics.LogStore = Metrics.newStore();
  let metrics = Metrics.CnsMetrics(metricsStore);

  // TODO: discuss metrics approach, using store vs. logs
  public shared func lookup(args : APITypes.LookupArgs) : async APITypes.LookupResponse {
    let result = Queries.lookup(myTld, domainRecordsStore, args.domain, args.recordType);
    metrics.addEntry(metrics.makeLookupEntry(args.domain, args.recordType, result.answers != []));
    return result;
  };

  // TODO: discuss metrics approach, using store vs. logs
  // TODO: discuss if the RegistrationRecords type with RegistrationController and RegistrationControllerRole is neeeded at this point?
  public shared ({ caller }) func register(args: APITypes.RegisterArgs) : async (APITypes.RegisterResult) {
    if (not Principal.isController(caller)) trap("Not authorized");

    let result = Mutations.register(domainRecordsStore, myTld, args.domain, args.principal, args.records);
    metrics.addEntry(metrics.makeRegisterEntry(args.domain, "TODO", result.success));
    return result;
  };

  public shared query ({ caller }) func get_metrics({ period : Text }) : async Result.Result<Metrics.MetricsData, Text> {
    if (not Principal.isController(caller)) trap("Not authorized");

    #ok(metrics.getMetrics(period, [("cidRecordsCount", Map.size(domainRecordsStore.domainToRecordsMap))]));
  };

  public shared ({ caller }) func purge_metrics() : async Result.Result<Nat, Text> {
    if (not Principal.isController(caller)) trap("Not authorized");

    return #ok(metrics.purge());
  };
};
