public class IRR_SVC_ICouponService {
    

    public static List<IRR_MOD_ICouponInfo> createFlightIrregulraity(IRR_MOD_DelayInfo delayInfo,Map<String ,List<String>> classWithPassenger) {
         return service().createFlightIrregulraity(delayInfo,classWithPassenger);
      }



  private static IRR_SVC_IICouponService service() {
      return (IRR_SVC_IICouponService) IRR_Application.Service.newInstance(IRR_SVC_IICouponService.class);
  }

  public class IcouponException extends Exception { }
}