import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Case_RECORDTYPE_FIELD from '@salesforce/schema/Case.RecordTypeId';
import { getRecord } from "lightning/uiRecordApi";
export default class Fcs_CaseTag extends LightningElement {
    @api recordId;
    @track recordTypeId;
    @track
    case;
    @api error = 'initialley';
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [Case_RECORDTYPE_FIELD]
    })
    getCase({
        error,
        data
    }) {
        if (data) {
            var result = JSON.parse(JSON.stringify(data));
            this.account = result;
            this.recordTypeId = result.fields.RecordTypeId.value;
        } else if (error) {
            var result = JSON.parse(JSON.stringify(error));
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