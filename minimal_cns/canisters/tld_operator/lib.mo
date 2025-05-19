import APITypes "api_types";
import Map "mo:base/Map";
import Metrics "../../common/metrics";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Types "../../common/cns_types";
import Mutations "mutations";
import Queries "queries";

actor TldOperator {
  let myTld = ".icp.";
  type DomainRecordsMap = Map.Map<Text, Types.RegistrationRecords>;
  stable var lookupAnswersMap : DomainRecordsMap = Map.empty();

  stable var metricsStore : Metrics.LogStore = Metrics.newStore();
  let metrics = Metrics.CnsMetrics(metricsStore);

  public shared func lookup(args : APITypes.LookupArgs) : async APITypes.LookupResponse {
    Queries.lookup(myTld, lookupAnswersMap, Metrics.CnsMetrics(metricsStore), args.domain, args.recordType);
  };

  public shared ({ caller }) func register(args: APITypes.RegisterArgs) : async (APITypes.RegisterResult) {
    let domainLowercase : Text = Text.toLower(args.domain);
    let (result, recordType) = Mutations.validateAndRegister(caller, myTld, lookupAnswersMap, domainLowercase, args.records);
    metrics.addEntry(metrics.makeRegisterEntry(domainLowercase, recordType, result.success));
    return result;
  };

  public shared query ({ caller }) func get_metrics({ period : Text }) : async Result.Result<Metrics.MetricsData, Text> {
    if (not Principal.isController(caller)) {
      return #err("Currently only a controller can get metrics");
    };
    return #ok(metrics.getMetrics(period, [("cidRecordsCount", Map.size(lookupAnswersMap))]));
  };

  public shared ({ caller }) func purge_metrics() : async Result.Result<Nat, Text> {
    if (not Principal.isController(caller)) {
      return #err("Currently only a controller can purge metrics");
    };
    return #ok(metrics.purge());
  };
};
