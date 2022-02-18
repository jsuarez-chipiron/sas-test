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
      new Set<Id>(contentVersionIds),
      true
    );

    for (ContentVersion cv : cvs) {
      if (cv.Title.startsWith('CARE_PAYMUL_')) {
        processPaymulStatusReport(cv);
      } else if (cv.Title.startsWith('CARE_PAINL1_')) {
        processL1StatusReport(cv);
      } else if (cv.Title.startsWith('CARE_PAINL2_')) {
        processL2StatusReport(cv);
      } else if (cv.Title.startsWith('CARE_RACERGL_')) {
        processAccountingStatusReport(cv);
      }
    }
  }

  private static Void processPaymulStatusReport(ContentVersion cv) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    String fileContents = cv.VersionData.toString();
    List<String> lines = fileContents.split('\n');

    for (String line : lines) {
      List<String> dataFields = line.split('[|]');
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
        .markAsReceivedByRacer(documentStatus, errorDetail, uow);
    }
    uow.commitWork();
  }

  private static Void processL1StatusReport(ContentVersion cv) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    String fileContents = cv.VersionData.toString();
    List<String> lines = fileContents.split('\n');

    for (String line : lines) {
      List<String> dataFields = line.split('[|]');
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
      String errorDetail = dataFields[5];

      List<Settlement__c> correspondingSettlements = settlementsSel.selectByPaymentFileName(
        paymentFileName
      );

      Settlements.newInstance(correspondingSettlements)
        .markAsReceivedByBank(documentStatus, errorDetail, uow);
    }
    uow.commitWork();
  }

  private static Void processL2StatusReport(ContentVersion cv) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    String fileContents = cv.VersionData.toString();
    List<String> lines = fileContents.split('\n');

    for (String line : lines) {
      List<String> dataFields = line.split('[|]');
      /**
       * dataFields contents by index:
       *  0 - L2 received date
       *  1 - related file name
       *  2 - document type
       *  3 - payment instruction id
       *  4 - payment number
       *  5 - payment reference number
       *  6 - debtor account number
       *  7 - account holder name
       *  8 - payment method
       *  9 - payment status
       *  10 - payment status code
       *  11 - payment status info
       *  12 - amount
       *  13 - currency
       *  14 - payment date
       *  15 - paid to
       *  16 - trx status
       *  17 - trx code
       *  18 - trx info
       */

      String paymentFileName = dataFields[1];
      String documentStatus = dataFields[4];
      String errorDetail = dataFields[18];

      // There should never be more than a few lines so having this within the loop should be fine.
      List<Settlement__c> correspondingSettlements = settlementsSel.selectByPaymentFileName(
        paymentFileName // TODO: How do we actually find the correct one?
      );
      Settlements.newInstance(correspondingSettlements)
        .markAsFailedPayment(errorDetail, uow);
    }

    uow.commitWork();
  }

  private static Void processAccountingStatusReport(ContentVersion cv) {
    String fileContents = cv.VersionData.toString();
    // There should be only a single line.
    List<String> dataFields = fileContents.split('[|]');
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