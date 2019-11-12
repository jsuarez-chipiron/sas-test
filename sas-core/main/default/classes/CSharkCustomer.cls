public with sharing class CSharkCustomer {
    public CustomerGetResponse customerGetResponse {get; set;}

    public class CustomerGetResponse{
        public CustomergetResult customerGetResult {get; set;}
    }

    public class CustomerGetResult{
        public String birthDate {get; set;}
        public String firstName {get; set;}
        public String lastName {get; set;}
        public String middleName {get; set;}
        public String title {get; set;}
        public String gender {get; set;}
        public String salutation {get; set;}
        public String identifier {get; set;}
        public List<Engagement> EngagementList {get; set;}
    }

    public class Engagement{
        public String EngagementType {get; set;}
        public Profile profile {get; set;}
    }

    public class Profile{
        public List<PhysicalAddress> PhysicalAddresses {get; set;}
        public List<VirtualAddress> VirtualAddresses {get; set;}
    }

    public class PhysicalAddress{
        public String addressLine1 {get; set;}
        public String addressLine2 {get; set;}
        public String addressLine3 {get; set;}
        public String attention {get; set;}
        public String bounced {get; set;}
        public String cityName {get; set;}
        public String countryCode {get; set;}
        public String countyState {get; set;}
        public String department {get; set;}
        List<AddressFunction> Functions {get; set;}
        public String postOfficeBox {get; set;}
        public String zipCode {get; set;}

    }

    public class VirtualAddress{
        public String virtualAddressLine {get; set;}
        List<AddressFunction> Functions {get; set;}   
    }
    public class AddressFunction{
        public String functionName {get; set;}
    }

    public Engagement getEngagement(String engagementName){
        for(Engagement engagement:customerGetResponse.customerGetResult.EngagementList){
            if(engagement.EngagementType == 'a:' + engagement) return engagement;
        }
        return null;
    }
}
