/**
    Logging framework to ensures that events can be logged in the platform
    Commonly used to log errors
*/
public with sharing class C_Log {
    /**
        Timestamp when the log class was first initated
    */
    private static Long TS;
    /**
        The severity types logs in created
    */
    public enum Severity {Info, Warning, Error}
    /**
        Stores the start time of the transaction
        Note: Calling this method is not required for generating logs but is useful
        for establishing the duration of a transaction
    */
    public static void init(){
        if(TS==null)TS = System.currentTimeMillis();
    }
    /**
        Creates a log record
        @param severity The severity of the log record
        @param msg The message to log
        @param stackTrace The strack trace to log 
        @param logGroup The group of logs to which the log record belongs
        @param http HTTP inforamation supplied in the log
    */
    public static void log(Severity severity,String msg,String stackTrace,String logGroup,HttpData http){
        Long tsNow = System.currentTimeMillis();
        C_Log__c l = new C_Log__c();
        l.Severity__c = severity.name();
        if(msg!=null)l.Message__c = msg.abbreviate(10000);
        if(stackTrace!=null)l.StackTrace__c = stackTrace.abbreviate(10000);
        l.LogGroup__c = logGroup;
        if(http!=null)http.setRecord(l);
        l.Timestamp__c = tsNow;
        if(TS!=null)l.Duration__c = tsNow-TS;
        l.Transaction__c = C_Util.getUUID();
        insert l;
    }
    /**
        Logs an error from an exception
        @param e The exception which should be logged
        @param logGroup The group of logs to which the log record belongs
        @param http HTTP inforamation supplied in the log
    */
    public static void logException(Exception e,String logGroup,HttpData http){
        log(Severity.Error,e.getMessage(),e.getStackTraceString(),logGroup,http);
    }

    /**
        HTTP data which can be logged to a record
    */
    public class HttpData{
        /**
            The HTTP resource
        */
        public String resource;
        /**
            The HTTP method
        */
        public String method;
        /**
            The IP address of the remote host which initated the request
        */
        public String remoteAddress;
        /**
            The HTTP headers sent when calling the REST resource
        */
        public String headers;
        /**
            The query parameters sent when calling the REST resoruce
        */
        public String queryParams;
        /**
            The body sent when calling the REST resource
        */
        public String body;
        /**
            Sets the HTTP information on the supplied log record
            @param l The log record
        */
        private void setRecord(C_Log__c l){
            if(resource!=null)l.HttpResource__c = resource.abbreviate(255);
            if(method!=null)l.HttpMethod__c = method.abbreviate(10);
            if(remoteAddress!=null)l.HttpRemoteAddress__c = remoteAddress.abbreviate(60);
            if(headers!=null)l.HttpHeaders__c = headers.abbreviate(10000);
            if(queryParams!=null)l.HttpQueryParameters__c = queryParams.abbreviate(10000);
            if(body!=null)l.HttpBody__c = body.abbreviate(100000);
        }
    }
}
