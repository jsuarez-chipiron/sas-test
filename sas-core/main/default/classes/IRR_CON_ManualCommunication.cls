/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Controller class for the Manual Communication LWC page.
*/

public class IRR_CON_ManualCommunication {

    private static final String EVENT_TYPE = 'manualCommunication';
    private static final String AIRLINE = 'SK';

    @AuraEnabled
    public static List<IRR_MOD_PassengerInfo> getBookingPassengerInfos(String bookings) {
        String currentBookingReference;
        try {
            List<String> splitBookingReferences = bookings.split(',');
            List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();
            for (String bookingReference : splitBookingReferences) {
                if (String.isBlank(bookingReference)) continue;
                currentBookingReference = bookingReference;
                passengerInfos.addAll(IRR_SVC_TedsService.getPassengerInfosForBooking(bookingReference));
            }
            return passengerInfos;
        }
        catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(currentBookingReference + ' - ' + e.getMessage());
            ahe.setMessage(currentBookingReference + ' - ' + e.getMessage());
            throw ahe;
        }
    }

    @AuraEnabled
    public static List<IRR_MOD_PassengerInfo> getAdvancedFilterPassengerInfos(String bookingIds) {
        List<String> currentBookingFilter;
        String departureStation;
        String arrivalStation;
        String departureDate;
        String arrivalDate;
        try {
            List<String> splitBookingFilters = bookingIds.split(',');
            List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();
            for (String bookingFilter : splitBookingFilters) {
                if (String.isBlank(bookingFilter)) continue;
                currentBookingFilter = bookingFilter.split('!');
                departureStation = currentBookingFilter.size() >= 1 && String.isNotBlank(currentBookingFilter[0]) ? currentBookingFilter[0] : null ;
                arrivalStation = currentBookingFilter.size() >= 2 && String.isNotBlank(currentBookingFilter[1]) ? currentBookingFilter[1] : null;
                departureDate = currentBookingFilter[2] ;
                arrivalDate = currentBookingFilter[3] ;
                passengerInfos.addAll(IRR_SVC_TedsService.getPassengerInfosForBookingFilters(departureStation,arrivalStation,departureDate,arrivalDate));
            }
            return passengerInfos;
        }
        catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(currentBookingFilter + ' - ' + e.getMessage());
            ahe.setMessage(currentBookingFilter + ' - ' + e.getMessage());
            throw ahe;
        }
    }

    @AuraEnabled
    public static List<IRR_MOD_PassengerInfo> getFlightPassengerInfos(String flightIds) {
        String currentFlightId;
        try {
            List<String> splitFlightIds = flightIds.split(',');
            List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();
            for (String flightId : splitFlightIds) {
                currentFlightId = flightId;
                passengerInfos.addAll(IRR_SVC_TedsService.getPassengerInfosForFlight(flightId));
            }
            return passengerInfos;
        }
        catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(currentFlightId + ' - ' + e.getMessage());
            ahe.setMessage(currentFlightId + ' - ' + e.getMessage());
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