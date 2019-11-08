
   /**
    Test method for the process to route cases created from SoMe Posts to right queue
*/

@isTest 
private class CaseAssignOwnerOnCreation_Test { 
    /**
        Test create case from facebook post
    */
    @isTest 
    static void newFacebookCase(){ 
        Case c1 = new Case (Status='New', Origin='Facebook'); 
        insert c1; 
        System.assertEquals('00G', String.valueOf([SELECT OwnerId FROM Case WHERE Id = :c1.Id].OwnerId).Substring(0,3));  
    }

    /**
        Test create case from twitter post
    */
    @isTest 
    static void newTwitterCase(){
            SocialPost s2 = new SocialPost (Name='TestPost', Headline='TestHeadline');
            insert s2;  
            Case c2 = new Case (Status='New', Origin='Twitter'); 
            insert c2;
            System.assertEquals('00G', String.valueOf([SELECT OwnerId FROM Case WHERE Id = :c2.Id].OwnerId).Substring(0,3)); 
    } 

    /**
        Test create case (not SoMe)
    */
    @isTest 
    static void newNonSoMeCase(){
            Case c2 = new Case (Status='New', Origin='Email'); 
            insert c2;
            System.assertNotEquals('00G', String.valueOf([SELECT OwnerId FROM Case WHERE Id = :c2.Id].OwnerId).Substring(0,3)); 
    } 
 }

