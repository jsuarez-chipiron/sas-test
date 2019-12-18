/**
 * @author Anton Norell
 * @date 2019-12-18
 * @description JS constoller for component used to generate GDPR extract for a customer.
 */
import { LightningElement, track, api } from "lwc";
import generateExtractFile from "@salesforce/apex/AccountGDPRExtractController.generateExtractFile";
import { deleteRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AccountGdprExtract extends LightningElement {
  /**
   * Id for Account record in contect
   */
  @api recordId;

  /**
   * Variable to hold error. If assigned, the error is displayed in component.
   */
  @track error;

  /**
   * If true, a spinner is shown in component to indicate loading.
   */
  @track showSpinner;

  /**
   * Used to call controller to generate an extract for the customer in context. Opens a link to download the generated file.
   * @returns {Promise<void>}
   */
  async downloadExtract(){
    try{
      this.showSpinner = true;
      let contentVersion = await generateExtractFile({ accountId : this.recordId });
      window.open('/sfc/servlet.shepherd/version/download/' + contentVersion.Id);
      await deleteRecord(contentVersion.ContentDocumentId);
      this.showSpinner = false;

      const event = new ShowToastEvent({title: 'GDPR Extract', message: 'Extract generated successfully', variant: 'success'});
      this.dispatchEvent(event);
    } catch (error) {
      this.error = error;
      this.showSpinner = false,
      console.log('An error occured: ' + error);
    }
  }
}