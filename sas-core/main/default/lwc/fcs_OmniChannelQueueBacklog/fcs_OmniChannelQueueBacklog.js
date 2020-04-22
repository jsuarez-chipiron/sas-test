/**
 * Created by anorell on 2020-04-20.
 */

import { LightningElement, track } from "lwc";
import userId from '@salesforce/user/Id';
import getQueueIds from '@salesforce/apex/FCS_OmniChannelQueueBacklogController.getQueueIds';
import getQueueStatus from '@salesforce/apex/FCS_OmniChannelQueueBacklogController.getQueueStatus';

const columns = [
  { label: 'Queue', fieldName: 'queueName', wrapText: true},
  { label: 'Waiting', fieldName: 'countWaiting', type: 'number', cellAttributes: { alignment: 'left' }},
  { label: 'Longest wait time', fieldName: 'longestWaitTime'}
  ];

export default class FCS_OmniChannelQueueBacklog extends LightningElement {
  queueIds = undefined;
  showSpinner = false;
  queueStatus = [];
  columns = columns;

  connectedCallback() {
    this.refreshQueueStatus();
  }

  handleListRefresh() {
    this.refreshQueueStatus();
  }

  async refreshQueueStatus(){
    this.showSpinner = true;
    try{
      if(!this.queueIds){
        this.queueIds = await getQueueIds({userId: userId});
      }
      if (this.queueIds){
        this.queueStatus = await getQueueStatus({queueIds: this.queueIds});
      }
      this.showSpinner = false;
    } catch (error) {
      this.displayError(error);
    }
  }

  /**
   * Used to set parameters to display en error to the user.
   * @param error
   */
  displayError(error) {
    console.log("An error occurred: " + JSON.stringify(error));
    this.showSpinner = false;
    this.error = error;
  }
}