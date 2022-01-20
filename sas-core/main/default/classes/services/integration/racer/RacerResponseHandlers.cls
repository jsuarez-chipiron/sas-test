/**
 * A class for handling response files from RACER.
 *
 * See Confluence for more details on the formats and purposes of each of these
 * files.
 */
public class RacerResponseHandlers {
  private static ContentVersionsSelector contentVersionsSel = ContentVersionsSelector.newInstance();
  private static SettlementsSelector settlementsSel = SettlementsSelector.newInstance();
  private static SettlementItemsSelector settlementItemsSel = SettlementItemsSelector.newInstance();

  /**
   * Returns true if the file appears to be a file from RACER based on the
   * filename.
   */
  public static Boolean isARacerFile(String fileName) {
    return fileName.startsWith('CARE_PAYMUL_') ||
      fileName.startsWith('CARE_PAINL1_') ||
      fileName.startsWith('CARE_PAINL2_') ||
      fileName.startsWith('CARE_RACERGL_');
  }

  /**
   * Attempts to read and process the given ContentVersion objects as RACER
   * acceptance files.
   *
   * @param contentVersionIds
   */
  @future
  public static Void handle(List<Id> contentVersionIds) {
    List<ContentVersion> cvs = contentVersionsSel.selectById(
      new Set<Id>(contentVersionIds)
    );

    for (ContentVersion cv : cvs) {
      String fileContents = cv.VersionData.toString();
      List<String> dataFields = fileContents.split('|');

      if (cv.Title.startsWith('CARE_PAYMUL_')) {
        processPaymulStatusReport(dataFields);
      } else if (cv.Title.startsWith('CARE_PAINL1_')) {
        processL1StatusReport(dataFields);
      } else if (cv.Title.startsWith('CARE_PAINL2_')) {
        processL2StatusReport(cv);
      } else if (cv.Title.startsWith('CARE_RACERGL_')) {
        processAccountingStatusReport(dataFields);
      }
    }
  }

  private static Void processPaymulStatusReport(List<String> dataFields) {
    /**
     * dataFields contents by index:
     *  0 - processed date
     *  1 - file name
     *  2 - document type
     *  3 - payment count
     *  4 - document status: PROCESSED | FAILED
     *  5 - error detail
     *  6 - racer document id
     */

    String paymentFileName = dataFields[1];
    String documentStatus = dataFields[4];
    String errorDetail = dataFields[5];

    List<Settlement__c> correspondingSettlements = settlementsSel.selectByPaymentFileName(
      paymentFileName
    );

    Settlements.newInstance(correspondingSettlements)
      .markAsReceivedByRacer(documentStatus, errorDetail);
  }

  private static Void processL1StatusReport(List<String> dataFields) {
    /**
     * dataFields contents by index:
     *  0 - L1 received date
     *  1 - related file name
     *  2 - document type
     *  3 - payment count
     *  4 - document status: ACCEPTED | REJECTED
     *  5 - error detail
     *  6 - racer document id
     */

    String paymentFileName = dataFields[1];
    String documentStatus = dataFields[4];
    String errorDetail = dataFields[4];

    List<Settlement__c> correspondingSettlements = settlementsSel.selectByPaymentFileName(
      paymentFileName
    );

    Settlements.newInstance(correspondingSettlements)
      .markAsReceivedByBank(documentStatus, errorDetail);
  }

  private static Void processL2StatusReport(ContentVersion cv) {
    /**
     * dataFields contents by index:
     *  0 - L2 received date
     *  1 - related file name
     *  2 - document type
     *  3 - payment instruction id
     *  4 - payment number
     *  5 - debtor account number
     *  6 - account holder name
     *  7 - payment method
     *  8 - payment status
     *  9 - payment status code
     *  10 - payment status info
     *  11 - amount
     *  12 - currency
     *  13 - payment date
     *  14 - paid to
     *  15 - trx status
     *  16 - trx code
     *  17 - trx info
     */

    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    String fileContents = cv.VersionData.toString();
    List<String> lines = fileContents.split('\n');

    for (String line : lines) {
      List<String> dataFields = line.split('|');
      String paymentFileName = dataFields[1];
      String documentStatus = dataFields[4];
      String errorDetail = dataFields[17]; // TODO: What info we actually need from here.

      // There should never be more than a few lines so having this within the loop should be fine.
      List<Settlement__c> correspondingSettlements = settlementsSel.selectByPaymentFileName(
        paymentFileName // TODO: How do we actually find the correct one?
      );
      Settlements.newInstance(correspondingSettlements)
        .markAsFailedPayment(errorDetail, uow);
    }

    uow.commitWork();
  }

  private static Void processAccountingStatusReport(List<String> dataFields) {
    /**
     * dataFields contents by index:
     *  0 - processed date
     *  1 - file name
     *  2 - document type
     *  3 - transaction count
     *  4 - document status
     *  5 - error detail
     *  6 - document verification number
     */
    String accountingFileName = dataFields[1];
    String documentStatus = dataFields[4];
    String errorDetail = dataFields[5];

    List<Settlement_Item__c> correspondingSettlementItems = settlementItemsSel.selectByAccountingFileName(
      accountingFileName
    );
    SettlementItems.newInstance(correspondingSettlementItems)
      .markAsReceivedByRacer(documentStatus, errorDetail);
  }
}
