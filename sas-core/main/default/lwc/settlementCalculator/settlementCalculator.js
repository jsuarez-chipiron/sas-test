import { LightningElement, wire, api } from "lwc";
import { getRecord, getRecordNotifyChange } from "lightning/uiRecordApi";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import SETTLEMENT_ITEM_OBJECT from "@salesforce/schema/Settlement_Item__c";
import SETTLEMENT_OBJECT from "@salesforce/schema/Settlement__c";
import SETTLEMENT_CURRENCY_FIELD from "@salesforce/schema/Settlement__c.Currency__c";
import SETTLEMENT_STATUS_FIELD from "@salesforce/schema/Settlement__c.Settlement_Status__c";
import COST_ACCOUNT_FIELD from "@salesforce/schema/Settlement_Item__c.Cost_Account__c";
import CASE_RECORD_TYPE_FIELD from "@salesforce/schema/Settlement__c.Claim__r.Case__r.RecordType.Name";

import addSettlementsItemsToSettlement from "@salesforce/apex/SettlementsController.addSettlementsItemsToSettlement";
import getSettlement from "@salesforce/apex/SettlementsController.getSettlement";
import getCustomers from "@salesforce/apex/SettlementsController.getPassengers";
import getExchangeRates from "@salesforce/apex/SettlementsController.getExchangeRates";

export default class SettlementCalculator extends LightningElement {
  @api recordId;
  lastModifiedDate;
  settlementItemRecordTypeId;
  settlementRecordTypeInfos;

  rows = [
    {
      idx: 0,
      amount: 0,
      customer: undefined,
      costAccount: undefined,
      comments: undefined
    }
  ];
  costAccountOptions = [];
  settlementCurrency;
  customerOptions;

  MAX_LIABILITY_IN_XDR = 1288;
  COST_ACCOUNTS_BAGGAGE = ["6741", "6742", "6743"];
  maxLiabilityInSettlementCurrency = 0;
  customersExceedingMaxLiability = [];
  isBaggageClaim = false;

  showSpinner = false;
  dirty = false;
  error = undefined;
  cannotBeUpdated = false;
  type = {
    isEuroBonusPoints: false,
    isMonetary: false,
    isVoucher: false
  };

  CASE_RECORD_TYPE_TO_CREATE_SETTLEMENT = [
    "Customer Claim",
    "Claim",
    "Emergency"
  ];
  SETTLEMENT_STATUS_TO_MODIFY_SETTLEMENT_ITEM = ["In progress", "Denied"];

  get amountLabel() {
    return `Amount (${this.settlementCurrency})`;
  }

  get maxLiabilityDescription() {
    return `Maximum liability: <b>${this.maxLiabilityInSettlementCurrency}</b> ${this.settlementCurrency}  |  <b>${this.MAX_LIABILITY_IN_XDR}</b> SDR`;
  }

  get maxLiabilityWarning() {
    return `Warning: Total amount for ${this.customersExceedingMaxLiability.join(
      ", "
    )} exceeds maximum liability`;
  }

  get warnMaxLiability() {
    return this.customersExceedingMaxLiability.length > 0;
  }

  get totals() {
    const total = this.rows.reduce((prev, curr) => prev + curr.amount, 0);
    const currenciesToShow = [
      { currency: this.settlementCurrency, amount: total }
    ];
    if (this.settlementCurrency !== "EUR") {
      currenciesToShow.push({
        currency: "EUR",
        amount: total * this.exchangeRates.eur
      });
    }
    if (this.settlementCurrency !== "SEK") {
      currenciesToShow.push({
        currency: "SEK",
        amount: total * this.exchangeRates.sek
      });
    }
    if (this.settlementCurrency !== "USD") {
      currenciesToShow.push({
        currency: "USD",
        amount: total * this.exchangeRates.usd
      });
    }
    return {
      currencyText: `Total settlement: ${currenciesToShow
        .map(
          (entry) =>
            `<b>${Math.round(entry.amount * 100) / 100}</b> ${entry.currency}`
        )
        .join("  |  ")}`,
      points: total
    };
  }

  exchangeRates = {
    sek: 0,
    usd: 0,
    eur: 0,
    xdr: 0
  };

  @wire(getObjectInfo, { objectApiName: SETTLEMENT_ITEM_OBJECT })
  wiredObjectInfo({ data }) {
    if (data) {
      this.settlementItemRecordTypeId = data.defaultRecordTypeId;
    }
  }

  @wire(getObjectInfo, { objectApiName: SETTLEMENT_OBJECT })
  wiredSettlementObjectInfo({ data }) {
    if (data) {
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

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      SETTLEMENT_CURRENCY_FIELD,
      SETTLEMENT_STATUS_FIELD,
      CASE_RECORD_TYPE_FIELD
    ]
  })
  wiredSettlement({ error, data }) {
    if (!error && data) {
      //caseRecordType fetch value for case record name as the case record name from settlement
      //could be access through claim__r.case__r.RecordType.Name
      const caseRecordType =
        data.fields.Claim__r.value.fields.Case__r.value.fields.RecordType.value
          .fields.Name.value;
      const settlementStatus = data.fields.Settlement_Status__c.value;

      this.cannotBeUpdated =
        !this.SETTLEMENT_STATUS_TO_MODIFY_SETTLEMENT_ITEM.includes(
          settlementStatus
        ) ||
        !this.CASE_RECORD_TYPE_TO_CREATE_SETTLEMENT.includes(caseRecordType);
      this.type = {
        isEuroBonusPoints: data.recordTypeInfo.name === "EB points",
        isMonetary:
          data.recordTypeInfo.name === "Monetary" ||
          data.recordTypeInfo.name === "Cheque",
        isVoucher: data.recordTypeInfo.name === "Voucher"
      };
      this.lastModifiedDate = data.lastModifiedDate;
      if (!this.type.isEuroBonusPoints) {
        this.settlementCurrency = data.fields.Currency__c.value;
      } else {
        this.settlementCurrency = "Points";
      }
    }
  }

  @wire(getExchangeRates, {
    fromCurrency: "XDR",
    toCurrency: "$settlementCurrency"
  })
  getExchangeRate({ error, data }) {
    const ratesFound = !error && data != undefined && data.length > 0;
    if (ratesFound) {
      this.exchangeRates = {
        ...this.exchangeRates,
        xdr: data.find((a) => a.To_Currency__c === this.settlementCurrency)
          ? data.find((a) => a.To_Currency__c === this.settlementCurrency)
              .Rate__c
          : 0
      };
      this.maxLiabilityInSettlementCurrency =
        Math.round(this.MAX_LIABILITY_IN_XDR * this.exchangeRates.xdr * 100) /
        100;
    }
  }

  @wire(getSettlement, {
    settlementId: "$recordId",
    lastModifiedDate: "$lastModifiedDate"
  })
  wiredSettlementWithItems({ error, data }) {
    // Only used to get settlement items.
    // TODO: Move to a cleaner approach with getRecord, or something.
    const settlementFound = !error && data != undefined && data.length === 1;
    if (settlementFound) {
      const settlement = data[0];
      this.isBaggageClaim =
        settlement.Claim__r.Customer_Claim_Category__c === "Baggage";

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
            comments: settlementItem.Comments__c
          })
        );
        this.findCustomersAboveMaxLiability();
      } else {
        this.rows = [
          {
            idx: 0,
            amount: 0,
            customer: undefined,
            costAccount: undefined,
            comments: undefined
          }
        ];
      }
    } else {
      this.rows = [
        {
          idx: 0,
          amount: 0,
          customer: undefined,
          costAccount: undefined,
          comments: undefined
        }
      ];
    }
  }

  @wire(getCustomers, { settlementId: "$recordId" })
  getCustomers({ error, data }) {
    const customersFound = !error && data != undefined && data.length >= 1;
    if (customersFound) {
      this.customerOptions = data.map((x) => ({
        label: x.Name,
        value: x.Name
      }));
    }
  }

  @wire(getExchangeRates, {
    fromCurrency: "$settlementCurrency"
  })
  getExchangeRates({ error, data }) {
    const ratesFound = !error && data != undefined && data.length > 0;
    if (ratesFound) {
      this.exchangeRates = {
        ...this.exchangeRates,
        eur: data.find((a) => a.To_Currency__c === "EUR")
          ? data.find((a) => a.To_Currency__c === "EUR").Rate__c
          : 0,
        usd: data.find((a) => a.To_Currency__c === "USD")
          ? data.find((a) => a.To_Currency__c === "USD").Rate__c
          : 0,
        sek: data.find((a) => a.To_Currency__c === "SEK")
          ? data.find((a) => a.To_Currency__c === "SEK").Rate__c
          : 0
      };
    }
  }

  findCustomersAboveMaxLiability() {
    // Check if the sum of all settlement items grouped by customer is higher than the defined maximum liability per customer
    // Used to warn the agent if the amount is exceeded
    const settlementTypeHasMaxLiability =
      this.type.isMonetary || this.type.isVoucher;
    if (settlementTypeHasMaxLiability) {
      const totalsPerCustomer = this.rows.reduce((acc, row) => {
        if (this.COST_ACCOUNTS_BAGGAGE.includes(row.costAccount)) {
          acc[row.customer] =
            acc[row.customer] != undefined
              ? (acc[row.customer] += row.amount)
              : row.amount;
        }
        return acc;
      }, {});
      this.customersExceedingMaxLiability = Object.entries(totalsPerCustomer)
        .filter(
          (customer) => customer[1] > this.maxLiabilityInSettlementCurrency
        )
        .map((customer) => customer[0]);
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
    this.findCustomersAboveMaxLiability();
  }

  handleCustomerChange(event) {
    const rowIdx = this.rows.findIndex(
      (row) => row.idx == event.target.dataset.idx
    );
    this.rows = [...this.rows];
    this.rows[rowIdx] = { ...this.rows[rowIdx], customer: event.target.value };
    this.dirty = true;
    this.findCustomersAboveMaxLiability();
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
    this.findCustomersAboveMaxLiability();
  }

  handleCommentsChange(event) {
    const rowIdx = this.rows.findIndex(
      (row) => row.idx == event.target.dataset.idx
    );
    this.rows = [...this.rows];
    this.rows[rowIdx] = { ...this.rows[rowIdx], comments: event.target.value };
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
        comments: undefined
      }
    ];
    this.dirty = true;
    this.findCustomersAboveMaxLiability();
  }
  handleRemoveRow(event) {
    this.rows = this.rows.filter((row) => row.idx != event.target.dataset.idx);
    this.dirty = true;
    this.findCustomersAboveMaxLiability();
  }
  async handleSave() {
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
      Comments__c: row.comments,
      Id: row.id
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
