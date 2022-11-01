public without sharing class Currencies {
  public enum Code {
    AUD,
    AED,
    CAD,
    CHF,
    CNY,
    CZK,
    DKK,
    EUR,
    GBP,
    HKD,
    JPY,
    NOK,
    NZD,
    PLN,
    SEK,
    SGD,
    THB,
    USD
  }

  public static final Map<Code, String> CODE_ENUM_TO_PICKLIST_VALUE = new Map<Code, String>{
    Code.AUD => 'AUD',
    Code.AED => 'AED',
    Code.CAD => 'CAD',
    Code.CHF => 'CHF',
    Code.CNY => 'CNY',
    Code.CZK => 'CZK',
    Code.DKK => 'DKK',
    Code.EUR => 'EUR',
    Code.GBP => 'GBP',
    Code.HKD => 'HKD',
    Code.JPY => 'JPY',
    Code.NOK => 'NOK',
    Code.NZD => 'NZD',
    Code.PLN => 'PLN',
    Code.SEK => 'SEK',
    Code.SGD => 'SGD',
    Code.THB => 'THB',
    Code.USD => 'USD'
  };

  public static final Map<String, Code> CODE_PICKLIST_VALUE_TO_ENUM = new Map<String, Code>{
    'AUD' => Code.AUD,
    'AED' => Code.AED,
    'CAD' => Code.CAD,
    'CHF' => Code.CHF,
    'CNY' => Code.CNY,
    'CZK' => Code.CZK,
    'DKK' => Code.DKK,
    'EUR' => Code.EUR,
    'GBP' => Code.GBP,
    'HKD' => Code.HKD,
    'JPY' => Code.JPY,
    'NOK' => Code.NOK,
    'NZD' => Code.NZD,
    'PLN' => Code.PLN,
    'SEK' => Code.SEK,
    'SGD' => Code.SGD,
    'THB' => Code.THB,
    'USD' => Code.USD
  };
}
