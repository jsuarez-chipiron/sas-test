/**
    Batch class which ensures that all bookings and  related to the bookings are deleted except flights after
    X number of days after last modified.
    @author Thippeswamy A
*/
global with sharing class GDPR_DeleteBooking_Batch extends SBS_ScheduledBatch{
    /**
        The date at which bookings will be removed
    */
    private DateTime lastRetentionDate;
    /**
        Initiates the batch class and extracts the date used to filter out Booking for removal
    */
    global GDPR_DeleteBooking_Batch(){
        lastRetentionDate = DateTime.newInstance(Date.today().addDays(-C_Settings.getSettings('GDPR').getInt('DeletePeriodBooking')),Time.newInstance(0,0,0,0));
    }

    /**
        Iterates over all Bookings LastModifieDdate before the retention period
        @param bc The batch context
    */
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Id FROM Booking__c Where LastModifiedDate<:lastRetentionDate');
    }


    /**
        Deletes the Bookings and related entities
        - Passengers
        - Segments
        @param bc The batchable context of the batch job
        @param sObjScope The Bookings to delete
    */
    global override void executeScope(Database.BatchableContext bc, SObject[] sObjScope){
        Integer sz = sObjScope.size();
        Set<Id> bookingIds = new Set<Id>();       
        for(Integer i=0;i<sz;i++){
            bookingIds.add(sObjScope[i].Id);
        }
        delete sObjScope;
    }

    
}