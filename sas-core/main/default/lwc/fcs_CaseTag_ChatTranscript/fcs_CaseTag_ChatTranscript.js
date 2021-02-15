import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import findCase from '@salesforce/apex/FCS_CaseTag_ChatTranscript_Controller.findCase';

export default class Fcs_CaseTag extends LightningElement {
    @api recordId;
    @track cse;
    @track error;
    @track RecordTypeId;
    @wire(findCase, {
        recordId: '$recordId'
    })
    wiredcse({
        error,
        data
    }) {
        if (data) {
            this.cse = data;
            this.RecordTypeId = cse.RecordTypeId;
        } else if (error) {
            this.cse = undefined;
            error = 'error occured';
        }
    }

    handleSuccess(event) {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'Submitted Successfully',
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }
    handleReset(event) {
        checkClick = 'reset';
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
    }
}