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

    handleAllCheckbox(event) {
        const fieldName = event.target.name;
        const checkBoxType = event.target.dataset.checkboxType;
        let newParameters = JSON.parse(JSON.stringify(this.filterParameters));

        if (event.detail.checked) {
            newParameters[fieldName] = '*';
        } else {
            delete newParameters[fieldName];
        }

        this.unsetOppositeCheckbox(fieldName, checkBoxType);
        this.applyFilter(newParameters);
    }

    handleNoneCheckbox(event) {
        const fieldName = event.target.name;
        const checkBoxType = event.target.dataset.checkboxType;
        let newParameters = JSON.parse(JSON.stringify(this.filterParameters));

        if (event.detail.checked) {
            newParameters[fieldName] = null;
        } else {
            delete newParameters[fieldName];
        }

        this.unsetOppositeCheckbox(fieldName, checkBoxType);
        this.applyFilter(newParameters);
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