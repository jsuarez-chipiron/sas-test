/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description TODO
 */

import {LightningElement} from 'lwc';

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

    filterParameters = {};

    handleValueSelect(event) {
        const fieldName = event.target.name;
        const value = event.detail.value;

        if (value && !(Array.isArray(value) && value.length === 0)) {
            this.filterParameters[fieldName] = value;
        } else {
            delete this.filterParameters[fieldName];
        }

        this.applyFilter();
    }

    handleAllCheckbox(event) {
        const fieldName = event.target.name;
        const checkBoxType = event.target.dataset.checkboxType;

        if (event.detail.checked) {
            this.filterParameters[fieldName] = '*';
        } else {
            delete this.filterParameters[fieldName];
        }

        this.unsetOppositeCheckbox(fieldName, checkBoxType);
        this.applyFilter();
    }

    handleNoneCheckbox(event) {
        const fieldName = event.target.name;
        const checkBoxType = event.target.dataset.checkboxType;

        if (event.detail.checked) {
            this.filterParameters[fieldName] = null;
        } else {
            delete this.filterParameters[fieldName];
        }

        this.unsetOppositeCheckbox(fieldName, checkBoxType);
        this.applyFilter();
    }

    unsetOppositeCheckbox(fieldName, thisCheckboxType) {
        this.template.querySelectorAll(`lightning-input[data-checkbox-field="${fieldName}"]`)
            .forEach(cmp => {
                if (cmp.dataset.checkboxType !== thisCheckboxType && cmp.checked) cmp.checked = false;
            });
    }

    applyFilter() {
        const event = new CustomEvent('applyfilter', {
            detail: this.filterParameters
        });
        setTimeout(() => { this.dispatchEvent(event); });
    }
}