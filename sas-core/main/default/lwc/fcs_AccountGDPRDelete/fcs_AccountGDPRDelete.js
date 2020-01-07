/**
 * @author Anton Norell
 * @date 2019-12-18
 * @description JS controller for component used to delete data for customer
 */
import { LightningElement, track, api } from "lwc";
//Add method for GDPR delete batch
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AccountGdprExtract extends LightningElement {
  /**
   * Id for Account record in context
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
   * Used to call controller to generate an extract for the customer in context. Opens a link to download the generated
   * file, and then deletes the file from Salesforce.
   * @returns {Promise<void>}
   */
  async deleteAccount(){
    try{
      this.showSpinner = true;
      //Method for deletion with await
      this.showSpinner = false;

      const event = new ShowToastEvent({title: 'GDPR Delete', message: 'Successfully deleted data', variant: 'success'});
      this.dispatchEvent(event);
    } catch (error) {
      this.error = error;
      this.showSpinner = false;
      console.log('An error occurred: ' + error);
    }
  }
}