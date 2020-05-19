/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Controller class for the Manual Communication LWC page.
*/

public class IRR_CON_ManualCommunication {

    private static final String EVENT_TYPE = 'manualCommunication';

    @AuraEnabled
    public static List<IRR_MOD_PassengerInfo> getBookingPassengerInfos(String bookingId) {
        try {
            return IRR_SVC_TedsService.getPassengerInfosForBooking(bookingId);
        }
        catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(e.getMessage());
            ahe.setMessage(e.getMessage());
            throw ahe;
        }
    }

    @AuraEnabled
    public static List<IRR_MOD_PassengerInfo> getFlightPassengerInfos(String flightId) {
        try {
            return IRR_SVC_TedsService.getPassengerInfosForFlight(flightId);
        }
        catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(e.getMessage());
            ahe.setMessage(e.getMessage());
            throw ahe;
        }
    }

    @AuraEnabled
    public static void sendManualCommunication(IRR_MOD_ManualRequest manualRequest) {
        try {
            IRR_SVC_CommunicationService.processEvent(EVENT_TYPE, manualRequest);
        }
        catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(e.getMessage());
            ahe.setMessage(e.getMessage());
            throw ahe;
        }
    }

    @AuraEnabled
    public static Map<String, List<ManualTemplate>> getManualTemplatesBySendMode() {
        try {
            List<IRR_ManualCommunicationTemplate__mdt> templates = IRR_SEL_ManualTemplatesSelector.newInstance()
                    .selectAllManualCommunicationTemplates();

            Set<String> manualTemplateNames = new Set<String>();
            for (IRR_ManualCommunicationTemplate__mdt mct : templates) {
                //Use SMS template if available, otherwise Email template
                String templateName = String.isNotBlank(mct.IRR_SMSTemplate__c) ? mct.IRR_SMSTemplate__c :
                        mct.IRR_EmailTemplate__c;
                if (!manualTemplateNames.contains(templateName)) {
                    manualTemplateNames.add(templateName);
                }
            }
            //Get Email Templates
            Map<String, EmailTemplate> emailTemplateByNames = IRR_SEL_EmailTemplatesSelector.newInstance()
                    .selectEmailTemplatesByName(manualTemplateNames);

            //Initialize ManualTemplate objects and sort them by Send Mode, skip non-existing Email Templates
            Map<String, List<ManualTemplate>> manualTemplatesBySendMode = new Map<String, List<ManualTemplate>>();
            for (IRR_ManualCommunicationTemplate__mdt mct : templates) {
                String templateName = String.isNotBlank(mct.IRR_SMSTemplate__c) ? mct.IRR_SMSTemplate__c.toLowerCase() :
                        mct.IRR_EmailTemplate__c.toLowerCase();
                if (!emailTemplateByNames.containsKey(templateName)) continue;

                ManualTemplate mt = new ManualTemplate(mct, emailTemplateByNames.get(templateName));
                if (!manualTemplatesBySendMode.containsKey(mct.IRR_SendMode__c)) {
                    manualTemplatesBySendMode.put(mct.IRR_SendMode__c, new List<ManualTemplate>());
                }

                manualTemplatesBySendMode.get(mct.IRR_SendMode__c).add(mt);
            }
            return manualTemplatesBySendMode;
        }
        catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(e.getMessage());
            ahe.setMessage(e.getMessage());
            throw ahe;
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