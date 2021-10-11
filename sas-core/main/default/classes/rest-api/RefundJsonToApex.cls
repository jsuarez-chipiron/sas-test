global class RefundJsonToApex {
  global cls_formData formData;
  global cls_metaData metaData;
  global class cls_formData {
    public String countryOfPurchase; //Sweden
    public String email; //example@example.com
    public String phone; //000000000000
    public String cancelEntireBooking; //yes|no|already-cancelled
    public String cancelAllPassengers; //yes|no|already-cancelled
    public String cancelDirection; //inbound|outbound
    public String bookedTripVia; //website|customer-service
    public String bookingReference; //0000AA
    public String ticketNumber; //123-1234567890
    public List<String> passengerNames; // passengerNames
  }
  global class cls_metaData {
    public String market; // se-sv
  }
  public static RefundJsonToApex parse(String json) {
    return (RefundJsonToApex) System.JSON.deserialize(
      json,
      RefundJsonToApex.class
    );
  }
}
