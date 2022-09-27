import { LightningElement,track,api } from 'lwc';
import distributionList from '@salesforce/label/c.Distribution_Lists';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendCsvEmail from "@salesforce/apex/IRR_CON_SendEmail.SendCsvEmail";
export default class IRR_HotelAccomodation extends LightningElement {

    @api emailPicklistOptions = [];

    @track recipients = [];

    @api isShowModal = false;

    @api passData ;
     
    @api fileName;

    @track toAddresses ='';

    showEmailPicklist = false;

    @track isDisabledSend = false;

    connectedCallback() {
        for(const emailList of distributionList.split(';')){
            const option = {
                label: emailList,
                value: emailList
            };
            this.emailPicklistOptions = [ ...this.emailPicklistOptions, option ];
        }
    }

    get modalClass() {
        return this.showRecipientModal ? 'slds-modal slds-fade-in-open' : 'slds-modal';
    }

    handleEmailChange(event) {

        this.toAddresses = event.detail.value;

    }
    showModalBox() {  
        this.isShowModal = true;
    }

    hideModalBox() {  
        this.isShowModal = false;
        const sendEvent = new CustomEvent('closehotelacc', {
            detail: false
        });
        this.dispatchEvent(sendEvent);

    }

    handleCancel(){
        this.isShowModal = false;
        const sendEvent = new CustomEvent('closehotelacc', {
            detail: false
        });
        this.dispatchEvent(sendEvent);
    }
    handleSend(event){
         if(this.toAddresses ==='' || this.toAddresses ===undefined){
            const toastEvent = new ShowToastEvent({
                title: 'No Address Selected',
                message: 'Please select an email.',
            });
            this.dispatchEvent(toastEvent);
            return ;
         }
         this.isDisabledSend = true;
         sendCsvEmail({CsvData: this.passData,FileName: this.fileName, SendTo : 'gaurav.singh@sas.dk'}).then(result => {
           //Show email msg 
            const toastEvent = new ShowToastEvent({
                title: 'Send successfuly',
                message: 'Email has been sent successfuly.',
            });
            this.dispatchEvent(toastEvent);
            //Hide model 
            this.isShowModal = false;
            const sendEvent = new CustomEvent('closehotelacc', {
                detail: false
            });
            this.dispatchEvent(sendEvent);
           })
           .catch(error => {
            this.handleError(error, true);
        });
    }
}