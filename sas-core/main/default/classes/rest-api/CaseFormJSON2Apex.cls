//
// Generated by JSON2Apex http://json2apex.herokuapp.com/
//

global class CaseFormJSON2Apex {
  global class FormData {
    global String bookingReference;
    global List<String> contentVersionIds;
  }

  global FormData formData;
  global MetaData metaData;

  global class MetaData {
    global String market;
  }

  public static CaseFormJSON2Apex parse(String json) {
    return (CaseFormJSON2Apex) System.JSON.deserialize(
      json,
      CaseFormJSON2Apex.class
    );
  }
}