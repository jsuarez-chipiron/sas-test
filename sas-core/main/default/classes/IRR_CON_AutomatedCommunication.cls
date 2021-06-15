/**
* @author Chetan Singh, Coforge
* @date 2021
*
* @description Controller class for the Automated Communication.
*/

public with sharing class IRR_CON_AutomatedCommunication {
    private static final String EVENT_TYPE = 'automatedCommunication';


    public static List<IRR_MOD_PassengerInfo> getPassengerInfos(String arrivalStation,String departureStation,String daysBeforeDepartureDate ) {
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();
        try {
            
            Date DepartureDate = System.today().addDays(integer.valueOf(daysBeforeDepartureDate));
            String DepDate = String.valueOf(DepartureDate) + 'T00:00:00.000Z';
            System.debug('<<DepDate>>'+DepDate);
            Date ArrivalDate = DepartureDate.addDays(2);
            String ArrDate = String.valueOf(ArrivalDate) + 'T00:00:00.000Z';
            passengerInfos.addAll(IRR_SVC_TedsService.getPassengerInfosForBookingFilters(departureStation,arrivalStation,DepDate,ArrDate));
            System.debug('<<utc>>'+passengerInfos.get(0).thisSegment.departureTimeUTC +'<<DepDate>>'+DepDate);
            List<IRR_MOD_PassengerInfo> paxInfos = new List<IRR_MOD_PassengerInfo>();
            DepDate = DepDate.substring(0,10);
            for(IRR_MOD_PassengerInfo pInfo: passengerInfos){
                String DepDateUTC = pInfo.thisSegment.departureTimeUTC.substring(0,10);

                 if(DepDateUTC == DepDate){
                     paxInfos.add(pInfo);
                 }

            }
            System.debug('<<passengerInfos>>'+passengerInfos.size() +'<<paxInfos>>'+paxInfos.size());
            return paxInfos;
        }
        catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(passengerInfos + ' - ' + e.getMessage());
            ahe.setMessage(passengerInfos + ' - ' + e.getMessage());
            throw ahe;
        }

    }

        public static void sendAutomatedCommunication(IRR_MOD_AutomatedRequest automatedRequest) {
            try {
                IRR_SVC_CommunicationService.processEvent(EVENT_TYPE, automatedRequest);
            }
            catch (Exception e) {
                AuraHandledException ahe = new AuraHandledException(e.getMessage());
                ahe.setMessage(e.getMessage());
                throw ahe;
            }
        }


        public static AutomatedTemplate getAutomatedTemplate( String automatedTemplateName) {
            try {
                List<IRR_ManualCommunicationTemplate__mdt> templates = IRR_SEL_ManualTemplatesSelector.newInstance()
                                                                            .selectAllManualCommunicationTemplates();
                
                Set<String> automatedTemplateNames = new Set<String>();
                IRR_ManualCommunicationTemplate__mdt mctd;
                    for (IRR_ManualCommunicationTemplate__mdt mct : templates) {
                    
                    //Use SMS template if available, otherwise Email template
                        String templateName = String.isNotBlank(mct.IRR_SMSTemplate__c) ? mct.IRR_SMSTemplate__c :
                        mct.IRR_EmailTemplate__c;
                        if(mct.IRR_SMSTemplate__c==automatedTemplateName || mct.IRR_EmailTemplate__c==automatedTemplateName){
                        templateName = automatedTemplateName;
                        automatedTemplateNames.add(templateName);
                        mctd = mct;
                        break;
                    }
                }
                //Get Email Templates
                Map<String, EmailTemplate> emailTemplateByNames = IRR_SEL_EmailTemplatesSelector.newInstance()
                                                                                        .selectEmailTemplatesByName(automatedTemplateNames);
                
                AutomatedTemplate mt = new AutomatedTemplate (mctd, emailTemplateByNames.get(automatedTemplateName));
                return mt;
            }
            catch (Exception e) {
                AuraHandledException ahe = new AuraHandledException(e.getMessage());
                ahe.setMessage(e.getMessage());
                throw ahe;
            }
        }
    
        public class AutomatedTemplate {
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
    
    
            public AutomatedTemplate(IRR_ManualCommunicationTemplate__mdt mct, EmailTemplate et) {
                templateLabel = mct.MasterLabel;
                templateName = mct.DeveloperName;
                emailTemplate = mct.IRR_EmailTemplate__c;
                defaultSendEmail = String.isNotBlank(emailTemplate) && mct.IRR_DefaultSendEmail__c;
                smsTemplate = mct.IRR_SMSTemplate__c;
                defaultSendSMS = String.isNotBlank(smsTemplate) && mct.IRR_DefaultSendSMS__c;
                // responseTemplate = mct.IRR_ResponseTemplate__c;
                String templateText = String.isNotBlank(et.HtmlValue) ? et.HtmlValue : et.Body;
                templatePreview = templateText.stripHtmlTags().replace('\n ', '\n')
                        .substringBeforeLast(IRR_SVC_CommunicationService.SAS_COPYRIGHT_NOTICE);
            }
        }
    
    }
