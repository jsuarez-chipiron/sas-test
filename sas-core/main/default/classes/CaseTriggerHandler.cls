public class CaseTriggerHandler extends C_TriggerHandler {
  
  public override void beforeInsert() {
    for(Case c : (List<Case>) Trigger.new) {
    // Route cases created from Social Posts to GlobalSupportSoMe-queue
    if(c.Origin =='Facebook' || c.Origin=='Twitter'){
        List<Group> SoMeQueue = [SELECT Id,DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName LIKE 'GlobalSupportSoMe'];
                c.OwnerId= SoMeQueue[0].Id; 
            }
    }
        }
        }
