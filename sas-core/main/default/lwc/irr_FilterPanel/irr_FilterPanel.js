/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description Filter component for the Manual Communication app.
 */

import {LightningElement, api} from 'lwc';

const segmentOptions = [
    { label: 'Cancelled', value: 'Cancelled' },
    { label: 'Confirmed', value: 'Confirmed' },
    { label: 'CallToConfirm', value: 'CallToConfirm' },
    { label: 'SpaceAvailable', value: 'SpaceAvailable' },
    { label: 'Suspended', value: 'Suspended' },
    { label: 'Unconfirmed', value: 'Unconfirmed' },
    { label: 'Waitlisted', value: 'Waitlisted' },
];

export default class IRR_FilterPanel extends LightningElement {

    segmentOptions = segmentOptions;

    @api filterParameters;

    get segmentStatusGroupValue() {
        return this.filterParameters['thisSegment.status'] || [];
    }

    handleValueSelect(event) {
        const fieldName = event.target.name;
        const value = event.detail.value;
        let newParameters = JSON.parse(JSON.stringify(this.filterParameters));

        if (value && !(Array.isArray(value) && value.length === 0)) {
            newParameters[fieldName] = value;
        } else {
            delete newParameters[fieldName];
        }

        this.applyFilter(newParameters);
    }

    handleSingleCheckbox(event) {
        const fieldName = event.target.name;
        let newParameters = JSON.parse(JSON.stringify(this.filterParameters));

        if (event.detail.checked) {
            let filterValue = event.target.dataset.checkboxFilterValue;
            filterValue = filterValue === "NULL" ? null : filterValue === "TRUE" ? true :
                filterValue === "FALSE" ? false : filterValue;
            newParameters[fieldName] = filterValue;
            if (fieldName === "hasThisSegment" && filterValue){
                newParameters['hasPrevSegment'] = false;
                newParameters['hasNextSegment'] = false;
            }
            this.unsetOtherGroupCheckboxes(event.target, newParameters);
            
        }
        else if (!event.detail.checked && fieldName === "hasThisSegment") {
            ['hasThisSegment', 'hasPrevSegment', 'hasNextSegment'].forEach(e => delete newParameters[e]);
        } 
        else {
            delete newParameters[fieldName];
        }

        this.applyFilter(newParameters);
    }

    unsetOtherGroupCheckboxes(thisComponent, newParameters) {
        const checkboxSingleGroup = thisComponent.dataset.checkboxSingleGroup;
        this.template.querySelectorAll(`lightning-input[data-checkbox-single-group="${checkboxSingleGroup}"]`)
            .forEach(loopComponent => {
                if (thisComponent !== loopComponent && loopComponent.checked) {
                    loopComponent.checked = false;
                    if (loopComponent.name === "hasThisSegment" && thisComponent.name === "hasPrevSegment") { 
                        ['hasThisSegment', 'hasNextSegment'].forEach(e => delete newParameters[e]);
                    }
                    else if(loopComponent.name === "hasThisSegment" && thisComponent.name === "hasNextSegment"){
                        ['hasThisSegment', 'hasPrevSegment'].forEach(e => delete newParameters[e]);

                    } else if(thisComponent !== loopComponent && (thisComponent.name == "hasPrevSegment" || thisComponent.name == "hasNextSegment")){
                        delete newParameters[loopComponent.name];
                    }
                }
            });
    }

    unsetOppositeCheckbox(fieldName, thisCheckboxType) {
        this.template.querySelectorAll(`lightning-input[data-checkbox-field="${fieldName}"]`)
            .forEach(cmp => {
                if (cmp.dataset.checkboxType !== thisCheckboxType && cmp.checked) cmp.checked = false;
            });
    }

    applyFilter(newParameters) {
        const event = new CustomEvent('applyfilter', {
            detail: newParameters
        });
        setTimeout(() => { this.dispatchEvent(event); });
    }
}