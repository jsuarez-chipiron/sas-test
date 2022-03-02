import { LightningElement, wire, api } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import CLAIM_BOOKING_REFERENCE_FIELD from '@salesforce/schema/LIA_Claim__c.Liability_PNR__c';
import CLAIM_CLAIMS_EXIST_IN_CARE_FOR_PNR_FIELD from '@salesforce/schema/LIA_Claim__c.Claims_Exist_In_CARE_For_PNR__c';

export default class SettlementCalculator extends LightningElement {
  @api recordId;
  settlementItemRecordTypeId;
  settlementRecordTypeInfos;
  potentialDuplicateClaimsInEDW = false;
  bookingReference;

  @wire(getRecord, { recordId: '$recordId', fields: [CLAIM_BOOKING_REFERENCE_FIELD, CLAIM_CLAIMS_EXIST_IN_CARE_FOR_PNR_FIELD] })
  wiredClaim({ data }) {
    if (data) {
      this.potentialDuplicateClaimsInEDW = data.fields.Claims_Exist_In_CARE_For_PNR__c.value;
      this.bookingReference = data.fields.Liability_PNR__c.value;
    }
  }
}