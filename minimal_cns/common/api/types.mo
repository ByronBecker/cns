import DomainTypes "../data/domain/types";
module {
  public type LookupArgs = {
    domain : Text;
    recordType : Text;
  };

  public type LookupResponse = {
    answers : [DomainTypes.DomainRecord];
    additionals : [DomainTypes.DomainRecord];
    authorities : [DomainTypes.DomainRecord];
  };

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

  public type RegistrationRecords = {
    controller : [RegistrationController];
    records : ?[DomainTypes.DomainRecord];
  };

  public type RegisterArgs = {
    domain : Text;
    principal : Principal;
    records : RegistrationRecords;
  };

  public type RegisterResult = {
    success : Bool;
    message : ?Text;
  };
}