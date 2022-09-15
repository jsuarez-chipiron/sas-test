/**
* @author Gaurav Singh, Coforge
* @date 2022
*
* @description This is the entry point for icoupon system.
*/
public class IRR_SVC_ICouponService {
    

    public static List<IRR_MOD_ICouponInfo> createFlightIrregularity(IRR_MOD_DelayInfo delayInfo,Map<String ,List<String>> classWithPassenger) {
         return service().createFlightIrregularity(delayInfo,classWithPassenger);
      }



  public static IRR_SVC_IICouponService service() {
      return (IRR_SVC_IICouponService) IRR_Application.Service.newInstance(IRR_SVC_IICouponService.class);
  }

  public class IcouponException extends Exception { }
}