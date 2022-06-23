public class IRR_CON_SendEmail {



    @AuraEnabled
    public static map<String,String> SendCsvEmail(String CsvData) {
        System.debug('CsvData -->' +CsvData); 
        map<String, String> result = new map<String, String> ();
        try{
            Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
            Blob csvBlob = blob.valueOf(CsvData);
            String csvName = 'PassengerInfo.xlsx';
            csvAttachment.setFileName(csvName);
            csvAttachment.setBody(csvBlob);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[]{'chetan.singh@coforge.com','chetan.singh@sas.dk','niit.csingh@iberia.es'};
            String subject = 'Test CVS Email';
            email.setSubject(subject);
            email.setToAddresses(toAddresses);
            email.setPlainTextBody('Test CSV Email');
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});
            Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            if (r[0].success) {
                System.debug('The email was sent successfully-->');
                result.put('SUCCESS', 'The email was sent successfully--->');
            } else {
                System.debug('The email failed to send--> ' + r[0].errors[0].message);
                result.put('ERROR', 'The email failed to send---> ' + r[0].errors[0].message);
            }
        }
        catch(Exception EX)
        {
            System.debug('The email failed to send----> ' + Ex.getMessage());
            result.put('ERROR', 'The email failed to send----> ' + Ex.getMessage());
        }
        System.debug('result-->' +result);
        return result;
    }

    
}
