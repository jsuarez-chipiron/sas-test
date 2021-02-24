/**
 * Helper for the email process in process builder.
 */
public inherited sharing class EmailProcessHelper {
    /**
     * Updates the owner of a case an email came in to be the queue of a department.
     */
    @InvocableMethod(label='Assign case to department queue')
    public static void UpdateCaseOwnerToDepartmentQueue(List<UpdateCaseArgs> args) {

        List<Case> casesToUpdate = new List<Case>();

        for (UpdateCaseArgs arg : args) {
            Case c = [SELECT Id, Department__c FROM Case WHERE Id =: arg.caseId];

            // Get the queue with the same name as the department.
            // There should be exactly one queue per department.
            List<Group> q = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name =: c.Department__c];
            
            if (q.size() == 1) {
                c.OwnerId = q[0].Id;
                casesToUpdate.add(c);
            }

        }

        if (casesToUpdate.size() > 0) {
            update casesToUpdate;
        }
    } 

    public class UpdateCaseArgs {
        @InvocableVariable(required=true)
        public ID caseId;

        public UpdateCaseArgs () {}

        public UpdateCaseArgs (ID caseId) {
            this.caseId = caseId;
        }
    }
}
