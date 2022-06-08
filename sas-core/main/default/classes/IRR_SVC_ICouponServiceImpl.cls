public class IRR_SVC_ICouponServiceImpl implements IRR_SVC_IICouponService {

    private static final String NAMED_CREDENTIAL = 'callout:SAS_APIM_ICOUPON';
    private static final String ICOUPON_Url = '/api/v2/flight/flightIrreg?preventDuplicates=true';
    private static final String AIRLINE_CODE = 'SK';
    private static final String REASON_COMMENT = 'Cancellation with passenger delay 2-3 hours';
    
    Public static List<IRR_MOD_ICouponInfo> classCoupons;
    Public static  List<ServiceClass__mdt> serviceClassList;

    public  IRR_SVC_ICouponServiceImpl(){
        serviceClassList =new List<ServiceClass__mdt>();
        classCoupons = new List<IRR_MOD_ICouponInfo>();
        List<ServiceClass__mdt> serviceMtdList =IRR_SEL_AutomatedServiceClassSelector.newInstance().selectAutomatedServiceClass();
        System.debug('serviceMtdList ++ ' +serviceMtdList);
        for(ServiceClass__mdt serviceMtd :serviceMtdList){
            
            serviceClassList.add(serviceMtd);
        }
        
      
    }

    private static C_IIntegrationExecutor integrationExecutor {
        get {
            if (integrationExecutor == null) {
                integrationExecutor =
                        IRR_Application.IntegrationExecutorBuilder.newInstance(IRR_Application.IntegrationType.REST)
                                .setBaseURL(NAMED_CREDENTIAL)
                                .enableSASTracking()
                                .build();
            }
            return integrationExecutor;
        }
        private set;
    }

  

    /**
     * @author Gaurav Singh, Coforge
     * @date 2020
     *
     * @description create Flight Irregulraity.
     *
     * @param 
     *
     * @return 
     */
    public List<IRR_MOD_ICouponInfo> createFlightIrregulraity(IRR_MOD_DelayInfo delayInfo,Map<String ,List<String>> classWithPassenger) {

        
        for(String key :  classWithPassenger.keySet()){
            
           createIcouponRequestBody(delayInfo,key,classWithPassenger);
        }
        return classCoupons;     
    }


    public ServiceClass__mdt selectCoupanValue(Integer delayInMinute,String airportCode, String serviceClass) {
        ServiceClass__mdt serviceMetadata = new ServiceClass__mdt();
        //Decimal couponVale =0;
        for(ServiceClass__mdt mtd :  serviceClassList){
            
           if( airportCode.toLowerCase()==  mtd.AirportCode__c.toLowerCase() &&
               serviceClass.toLowerCase()==mtd.Service_Class_Code__c.toLowerCase() &&
               mtd.Max_Delay__c !=null &&
               delayInMinute>=mtd.Min_Delay__c && delayInMinute < =mtd.Max_Delay__c
            ){
                serviceMetadata = mtd;
                break;
           }
           else if( airportCode.toLowerCase()==  mtd.AirportCode__c.toLowerCase() &&
                    serviceClass.toLowerCase()==mtd.Service_Class_Code__c.toLowerCase() &&
                    mtd.Max_Delay__c ==null &&
                    delayInMinute>=mtd.Min_Delay__c
           ){
               serviceMetadata = mtd;
                break;

           }
        }
        return serviceMetadata;     
    }

    
      private void createIcouponRequestBody(IRR_MOD_DelayInfo delayInfo,String serviceClass,Map<String ,List<String>> classWithPassenger) {
           Integer fliteNumber = getFliteNumber(delayInfo.flightRef);
          ServiceClass__mdt serviceMetadata =new ServiceClass__mdt();
          serviceMetadata = selectCoupanValue(delayInfo.delayedMinutes,delayInfo.stationDeparture,serviceClass);
           Decimal voucherAmount =serviceMetadata.CoupanValue__c;
           String currencyCode =serviceMetadata.Currency__c;
          
          
           Map<String, Object> icoupan = new Map<String, Object>{
                    'airportCode' => String.valueOf(delayInfo.stationDeparture),
                    'causingAirlineCode' =>String.valueOf(AIRLINE_CODE),
                    'causingFlightNumber' =>fliteNumber,
                    'causingFlightDate' => delayInfo.scheduledTimeOfDepartureUTC.Year()+'-'+delayInfo.scheduledTimeOfDepartureUTC.Month()+'-'+delayInfo.scheduledTimeOfDepartureUTC.Day(),//'2022-03-15', // delayInfo.scheduledTimeOfDepartureUTC,
                    'voucherValue' => voucherAmount,
                    'reasonComment' =>String.valueOf(REASON_COMMENT) ,
                    'RedemptionPassDetails' => new Map<String, Object> {
                                            'airlineCode' =>  String.valueOf(AIRLINE_CODE),
                                            'flightNumber' => fliteNumber,
                                            'flightDate' => delayInfo.scheduledTimeOfDepartureUTC.Year()+'-'+delayInfo.scheduledTimeOfDepartureUTC.Month()+'-'+delayInfo.scheduledTimeOfDepartureUTC.Day(),//  '2022-03-15',// delayInfo.scheduledTimeOfDepartureUTC,
                     'boardingSequences' => classWithPassenger.get(serviceClass)
                        
                                
                    }
            };
           
          IRR_MOD_ICouponInfo iCouponRes   = new IRR_MOD_ICouponInfo();
          if(voucherAmount!=null && currencyCode!=null)
          {
              callIcouponAPI(icoupan);
          iCouponRes.serviceClassCode = serviceClass;
          iCouponRes.voucherAmount = voucherAmount;
          iCouponRes.currencyCode = currencyCode;
          classCoupons.add(iCouponRes);
          }
         
       
    }
    
    Private  Integer getFliteNumber(String fliteNumber){
        String fNumber = fliteNumber.replaceAll('\\D+','');
        Integer fNumberInt = Integer.valueOf(fNumber);
        return fNumberInt;
    }

    
      public IRR_MOD_ICouponInfo callIcouponAPI(Map<String, Object> requestBody) {
        system.debug('ICOUPON_Url' +requestBody  );
        C_IntegrationExecutor.IntegrationResponse responseObject = integrationExecutor.executeRequest(
             ICOUPON_Url, C_IntegrationExecutor.Method.POST, requestBody, null);
        system.debug('ICOUPON_Url' +ICOUPON_Url  );
        system.debug('requestBody' +requestBody  );
        system.debug(responseObject.responseBody  );
        IRR_MOD_ICouponInfo iCouponRes = new IRR_MOD_ICouponInfo();
       if(responseObject.statusCode==200){
            system.debug('icoupon response ' + 	responseObject.responseBody);
            iCouponRes = (IRR_MOD_ICouponInfo)Json.deserialize(responseObject.responseBody, IRR_MOD_ICouponInfo.Class);
       }
        else if(responseObject.statusCode > 200){
       // throw new IRR_SVC_ICouponService.IcouponException(responseObject.responseBody);
        }
        return iCouponRes;
    }

   // private void throwTedsException(C_IntegrationExecutor.IntegrationResponse response) {
     //   throw new IRR_SVC_ICouponService.IcouponException(String.format(INTEGRATION_ERROR_TEMPLATE, new List<String>{
    //         String.valueOf(response.statusCode), response.responseBody}));
    //}

}