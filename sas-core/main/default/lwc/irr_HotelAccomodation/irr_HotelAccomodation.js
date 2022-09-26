import { LightningElement,track,api } from 'lwc';
import distributionList from '@salesforce/label/c.Distribution_Lists';


export default class IRR_HotelAccomodation extends LightningElement {

    @api emailPicklistOptions = [];

    @track recipients = [];


    showEmailPicklist = false;

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

    handleChange(event) {
        // this.recipients[recipientIndex] = event.target.value;
        const { name, value, dataset: { recipientIndex } } = event.target;
        this.recipients[recipientIndex][name] = value;
        console.log(`recipient : ${JSON.stringify(this.recipients)}`);
    }


}