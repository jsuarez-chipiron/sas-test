/**
 * Data structure and parser for TEDS Airport API v2 data
 */
public class TEDSAirport {
  public String id { get; set; }
  public String name { get; set; }
  public String city { get; set; }
  public Country country { get; set; }
  public Coordinates coordinates { get; set; }

  public class Country {
    public String name { get; set; }
    public String code { get; set; }
  }

  public class Coordinates {
    public String latitude { get; set; }
    public String longitude { get; set; }
  }

  private static final Map<String, String> REPLACEMENT_MAP = new Map<String, String>{
    'number' => 'number_x'
  };

  public static TEDSAirport parse(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      TEDSAirport.class,
      REPLACEMENT_MAP
    );
    return (TEDSAirport) jsonDeserializer.deserialize(json);
  }

  public static List<TEDSAirport> parseArray(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      List<TEDSAirport>.class,
      REPLACEMENT_MAP
    );

    return (List<TEDSAirport>) jsonDeserializer.deserialize(json);
  }
}
