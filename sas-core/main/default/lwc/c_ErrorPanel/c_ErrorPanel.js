import { LightningElement, api, track } from 'lwc';
import { reduceErrors } from 'c/c_LdsUtils';

export default class C_ErrorPanel extends LightningElement {
    /** Generic / user-friendly message */
    @api friendlyMessage = 'An error occurred when trying to perform the operation. Please try again and contact an administrator if the error persists.';

    @track viewDetails = false;

    /** Single or array of LDS errors */
    @api errors;
    
    get errorMessages() {
        return reduceErrors(this.errors);
    }

    handleCheckboxChange(event) {
        this.viewDetails = event.target.checked;
    }
}