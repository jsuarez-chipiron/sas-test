global class RefundJsonToApex {
  global FormData formData;
  global MetaData metaData;
  global class FormData {
    public String bookedTripVia; //website|customer-service
    public String bookingReference; //0000AA
    public String cancelAllPassengers; //yes|no|already-cancelled
    public String cancelDirection; //inbound|outbound
    public String cancelEntireBooking; //yes|no|already-cancelled
    public String countryOfPurchase; //Sweden
    public String email; //example@example.com
    public String firstName;
    public String lastName;
    public List<String> passengerNames; // passengerNames
    public String phone; //000000000000
    public String ticketNumber; //123-1234567890
  }
  global class MetaData {
    public String market; // se-sv
  }
  public static RefundJsonToApex parse(String json) {
    return (RefundJsonToApex) System.JSON.deserialize(
      json,
      RefundJsonToApex.class
    );
  }
}
