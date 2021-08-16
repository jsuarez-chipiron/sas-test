/**
* @author Chetan Singh, Coforge
* @date 2021
*
* @description Controller class for the Automated Communication.
*/

public with sharing class IRR_CON_AutomatedCommunication {
    private static final String EVENT_TYPE = 'automatedCommunication';


    public static List<IRR_MOD_PassengerInfo> getPassengerInfos(String departureStation,String arrivalStation,String daysBeforeDepartureDate ) {
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();
        try {
            Date DepartureDate = System.today().addDays(integer.valueOf(daysBeforeDepartureDate));
            String DepDate = String.valueOf(DepartureDate) + 'T00:00:00.000Z';
            Date ArrivalDate = DepartureDate.addDays(2);
            String ArrDate = String.valueOf(ArrivalDate) + 'T00:00:00.000Z';
            List<IRR_MOD_PassengerInfo> paxInfos = new List<IRR_MOD_PassengerInfo>();
            passengerInfos.addAll(IRR_SVC_TedsService.getPassengerInfosForBookingFilters(departureStation,arrivalStation,DepDate,ArrDate));
            DepDate = DepDate.substring(0,10);
            if(passengerInfos.size() > 0){
                for(IRR_MOD_PassengerInfo pInfo: passengerInfos) {
                String DepDateUTC = pInfo.thisSegment.departureTimeUTC.substring(0,10);
                    if(DepDateUTC == DepDate) {
                        paxInfos.add(pInfo);
                    }
                }
            }
            return paxInfos;    
        }
        catch (Exception e) {
             System.debug(passengerInfos + ' - ' + e.getMessage());
             throw e;
        }
         

    }

        public static void sendAutomatedCommunication(IRR_MOD_AutomatedRequest automatedRequest) {
            try {
                IRR_SVC_CommunicationService.processEvent(EVENT_TYPE, automatedRequest);
            }
            catch (Exception e) {
                System.debug(e.getMessage());
                throw e;
            }
        }


        public static ManualTemplate getManualTemplates( String automatedTemplateName) {
            try {

                //We are using same ManualCommunicationTemplate CMDT for automated communication as well
                List<IRR_ManualCommunicationTemplate__mdt> templates = IRR_SEL_ManualTemplatesSelector.newInstance()
                                                                            .selectAllManualCommunicationTemplates();
                
                Set<String> manualTemplateNames = new Set<String>();
                IRR_ManualCommunicationTemplate__mdt mctd;
                    for (IRR_ManualCommunicationTemplate__mdt mct : templates) {
                    
                    //Use SMS template if available, otherwise Email template
                        String templateName = String.isNotBlank(mct.IRR_SMSTemplate__c) ? mct.IRR_SMSTemplate__c :
                        mct.IRR_EmailTemplate__c;
                        if(mct.IRR_SMSTemplate__c==automatedTemplateName || mct.IRR_EmailTemplate__c==automatedTemplateName){
                        templateName = automatedTemplateName;
                        manualTemplateNames.add(templateName);
                        mctd = mct;
                        break;
                    }
                }
                //Get Email Templates
                Map<String, EmailTemplate> emailTemplateByNames = IRR_SEL_EmailTemplatesSelector.newInstance()
                                                                                        .selectEmailTemplatesByName(manualTemplateNames);
                
                ManualTemplate mt = new ManualTemplate (mctd, emailTemplateByNames.get(automatedTemplateName));
                return mt;
            }
            catch (Exception e) {
            System.debug('Email templates not found' + ' - ' + e.getMessage());
             throw e;
            }
        }
    
        public class ManualTemplate {
            @AuraEnabled
            public String templateLabel;
    
            @AuraEnabled
            public String templateName;
    
            @AuraEnabled
            public String emailTemplate;
    
            @AuraEnabled
            public String smsTemplate;
    
            @AuraEnabled
            public Boolean defaultSendEmail;
    
            @AuraEnabled
            public Boolean defaultSendSMS;
    
            @AuraEnabled
            public String templatePreview;
    
            @AuraEnabled
            public Boolean responseTemplate;
    
    
            public ManualTemplate(IRR_ManualCommunicationTemplate__mdt mct, EmailTemplate et) {
                templateLabel = mct.MasterLabel;
                templateName = mct.DeveloperName;
                emailTemplate = mct.IRR_EmailTemplate__c;
                defaultSendEmail = String.isNotBlank(emailTemplate) && mct.IRR_DefaultSendEmail__c;
                smsTemplate = mct.IRR_SMSTemplate__c;
                defaultSendSMS = String.isNotBlank(smsTemplate) && mct.IRR_DefaultSendSMS__c;
                responseTemplate = mct.IRR_ResponseTemplate__c;
                String templateText = String.isNotBlank(et.HtmlValue) ? et.HtmlValue : et.Body;
                templatePreview = templateText.stripHtmlTags().replace('\n ', '\n')
                        .substringBeforeLast(IRR_SVC_CommunicationService.SAS_COPYRIGHT_NOTICE);
            }
        }
    
    }
