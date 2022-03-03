import { LightningElement, wire, api } from "lwc";
import { getRecordNotifyChange } from "lightning/uiRecordApi";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import SETTLEMENT_ITEM_OBJECT from "@salesforce/schema/Settlement_Item__c";
import SETTLEMENT_OBJECT from "@salesforce/schema/Settlement__c";
import COST_ACCOUNT_FIELD from "@salesforce/schema/Settlement_Item__c.Cost_Account__c";

import addSettlementsItemsToSettlement from "@salesforce/apex/SettlementsController.addSettlementsItemsToSettlement";
import getSettlement from "@salesforce/apex/SettlementsController.getSettlement";
import getCustomers from "@salesforce/apex/SettlementsController.getPassengers";
import getExchangeRates from "@salesforce/apex/SettlementsController.getExchangeRates";

export default class SettlementCalculator extends LightningElement {
  @api recordId;
  settlementItemRecordTypeId;
  settlementRecordTypeInfos;

  rows = [{ idx: 0, amount: 0, customer: undefined, costAccount: undefined }];
  costAccountOptions = [];
  settlementCurrency;
  customerOptions;

  showSpinner = false;
  dirty = false;
  error = undefined;
  cannotBeUpdated = false;
  type = {
    isEuroBonusPoints: false,
    isMonetary: false,
    isVoucher: false
  };

  get amountLabel() {
    return `Amount (${this.settlementCurrency})`;
  }

  get totals() {
    const total = this.rows.reduce((prev, curr) => prev + curr.amount, 0);
    return {
      primaryAmount: total,
      primaryCurrency: this.settlementCurrency,
      secondaryAmount: this.settlementCurrency === 'USD' ? total * this.exchangeRates.eur : total * this.exchangeRates.usd,
      secondaryCurrency: this.settlementCurrency === 'USD' ? 'EUR' : 'USD',
      tertiaryAmount: this.settlementCurrency === 'SEK' ? total * this.exchangeRates.eur : total * this.exchangeRates.sek,
      tertiaryCurrency: this.settlementCurrency === 'SEK' ? 'EUR' : 'SEK',
      points: total
    };
  }

  exchangeRates = {
    sek: 0,
    usd: 0,
    eur: 0
  };

  @wire(getObjectInfo, { objectApiName: SETTLEMENT_ITEM_OBJECT })
  wiredObjectInfo({ data }) {
    if (data) {
      console.log('objectInfo', data)
      this.settlementItemRecordTypeId = data.defaultRecordTypeId;
    }
  }

  @wire(getObjectInfo, { objectApiName: SETTLEMENT_OBJECT })
  wiredSettlementObjectInfo({ data }) {
    if (data) {
      console.log('objectInfoSettlement', data)
      this.settlementRecordTypeInfos = data.recordTypeInfos;
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: "$settlementItemRecordTypeId",
    fieldApiName: COST_ACCOUNT_FIELD
  })
  wiredCostAccountPicklistValues({ data }) {
    if (data) {
      this.costAccountOptions = data.values;
    }
  }

  @wire(getSettlement, { settlementId: "$recordId" })
  wiredSettlement({ error, data }) {
    console.log('settlementData', data)
    const settlementFound = !error && data != undefined && data.length === 1;
    if (settlementFound) {
      const settlement = data[0];
      const notEuroBonus = true;
      if (notEuroBonus) {
        this.settlementCurrency = settlement.Currency__c;
      } else {
        this.settlementCurrency = "Points";
      }

      if (settlement.Settlement_Status__c !== "In progress") {
        this.cannotBeUpdated = true;
      }

      this.type = {
        isEuroBonusPoints: this.settlementRecordTypeInfos[settlement.RecordTypeId].name === 'EB points',
        isMonetary: this.settlementRecordTypeInfos[settlement.RecordTypeId].name === 'Monetary',
        isVoucher: this.settlementRecordTypeInfos[settlement.RecordTypeId].name === 'Voucher'
      }

      console.log('type', this.type)

      const hasSettlementItems =
        settlement.Settlement_Items__r != undefined &&
        settlement.Settlement_Items__r.length > 0;
      if (hasSettlementItems) {
        this.rows = settlement.Settlement_Items__r.map(
          (settlementItem, idx) => ({
            idx,
            id: settlementItem.Id,
            amount: settlementItem.Amount__c,
            customer: settlementItem.Customer_Name__c,
            costAccount: settlementItem.Cost_Account__c,
            comment: settlementItem.Comments__c
          })
        );
        console.log("getSettlement", this.rows);
      }
    } else {
      this.rows = [
        { idx: 0, amount: 0, customer: undefined, costAccount: undefined }
      ];
    }
  }

  @wire(getCustomers, { settlementId: "$recordId" })
  getCustomers({ error, data }) {
    const customersFound = !error && data != undefined && data.length === 1;
    if (customersFound) {
      this.customerOptions = data.map((x) => ({
        label: x.Name,
        value: x.Name
      }));
    }
  }

  @wire(getExchangeRates, { fromCurrency: "$settlementCurrency" })
  getExchangeRates({ error, data }) {
    const ratesFound = !error && data != undefined && data.length > 0;
    if (ratesFound) {
      this.exchangeRates = {
        eur: data.find(a => a.To_Currency__c === 'EUR') ?  data.find(a => a.To_Currency__c === 'EUR').Rate__c : 0,
        usd: data.find(a => a.To_Currency__c === 'USD') ?  data.find(a => a.To_Currency__c === 'USD').Rate__c : 0,
        sek: data.find(a => a.To_Currency__c === 'SEK') ?  data.find(a => a.To_Currency__c === 'SEK').Rate__c : 0
      }
    }
  }

  handleAmountChange(event) {
    const rowIdx = this.rows.findIndex(
      (row) => row.idx == event.target.dataset.idx
    );
    this.rows = [...this.rows];
    this.rows[rowIdx] = {
      ...this.rows[rowIdx],
      amount: Number(event.target.value)
    };
    this.dirty = true;
  }

  handleCustomerChange(event) {
    const rowIdx = this.rows.findIndex(
      (row) => row.idx == event.target.dataset.idx
    );
    this.rows = [...this.rows];
    this.rows[rowIdx] = { ...this.rows[rowIdx], customer: event.target.value };
    this.dirty = true;
  }

  handleCostAccountChange(event) {
    const rowIdx = this.rows.findIndex(
      (row) => row.idx == event.target.dataset.idx
    );
    this.rows = [...this.rows];
    this.rows[rowIdx] = {
      ...this.rows[rowIdx],
      costAccount: event.target.value
    };
    this.dirty = true;
  }

  handleCommentChange(event) {
    const rowIdx = this.rows.findIndex(
      (row) => row.id == event.target.dataset.idx
    );
    this.rows = [...this.rows];
    this.rows[rowIdx] = { ...this.rows[rowIdx], comment: event.target.value };
    this.dirty = true;
  }

  handleAddRow() {
    this.rows = [
      ...this.rows,
      {
        idx:
          this.rows.length === 0 ? 0 : this.rows[this.rows.length - 1].idx + 1,
        amount: 0,
        customer: undefined,
        costAccount: undefined,
        comment: undefined
      }
    ];
    this.dirty = true;
  }
  handleRemoveRow(event) {
    this.rows = this.rows.filter((row) => row.idx != event.target.dataset.idx);
    this.dirty = true;
  }
  async handleSave() {
    console.log("handleSave", this.rows);
    const areAllFieldsValid = [
      ...this.template.querySelectorAll("lightning-input"),
      ...this.template.querySelectorAll("lightning-combobox")
    ].reduce((validSoFar, inputCmp) => {
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true);
    if (!areAllFieldsValid) {
      return;
    }

    this.showSpinner = true;
    const settlementItems = this.rows.map((row) => ({
      Amount__c: row.amount,
      Cost_Account__c: row.costAccount,
      Customer_Name__c: row.customer,
      Comments__c: row.comments
    }));
    try {
      await addSettlementsItemsToSettlement({
        settlementId: this.recordId,
        settlementItems: settlementItems
      });
      getRecordNotifyChange([{ recordId: this.recordId }]);
      // TODO: Should we refresh also potentially existing settlement items and passengers
      this.dirty = false;
      this.showSpinner = false;
      this.error = undefined;
    } catch (error) {
      if (error.body && error.body.message) {
        this.error = error.body.message;
      } else {
        this.error = "An error happened";
      }
      this.showSpinner = false;
    }
  }
}
