/**
 * @author Anton Norell
 * @description Controller for component used to display queue status in component in utility bar
 * @date 2020-04-20
*/
public with sharing class FCS_OmniChannelQueueBacklogController {


    @AuraEnabled
    public static List<Id> getQueueIds(Id userId){
        Set<Id> groupsWithUser = new Set<Id>();
        //Populating the Group with User with GroupId we are filtering only for Group of Type Regular,Role and RoleAndSubordinates
        for(GroupMember u :[SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :userId AND (Group.Type = 'Regular' OR Group.Type='Role' OR Group.Type='RoleAndSubordinates')]) {
            groupsWithUser.add(u.GroupId);
        }

        Map<Id,Id> groupRoleMap = new Map<Id,Id>();
        //Populating the Map with RelatedID(i.e.UserRoledId) as Key
        for(Group gr : [SELECT Id, RelatedId, Name FROM Group]) {
            groupRoleMap.put(gr.RelatedId, gr.Id);
        }

        Set<Id> memberOfGroupIds = new Set<Id>();
        for(User u :[SELECT UserRoleId FROM User WHERE Id= :userId]) {
            if(groupRoleMap.containsKey(u.UserRoleId)) {
                memberOfGroupIds.add(groupRoleMap.get(u.UserRoleId));
            }
        }

        memberOfGroupIds.addAll(groupsWithUser);

        //Traversing the whole list of Groups to check any other nested Group
        Map<Id,Id> grMap = new Map<Id,Id>();
        for(GroupMember gr : [SELECT Id,UserOrGroupId,GroupId FROM GroupMember WHERE (Group.Type = 'Regular' OR Group.Type='Role' OR Group.Type='RoleAndSubordinates')]) {
            grMap.put(gr.UserOrGroupId,gr.GroupId);
        }
        for(Id i :memberOfGroupIds) {
            if(grMap.containsKey(i)) {
                memberOfGroupIds.add(grMap.get(i));
            }
        }

        GroupMember[] queueMemberships = [SELECT Id, Group.Name, Group.Type, GroupId FROM GroupMember WHERE (UserOrGroupId IN :memberOfGroupIds OR UserOrGroupId = :userId) AND Group.QueueRoutingConfigId != NULL];
        Id[] queueIds = new Id[]{};
        for(GroupMember member:queueMemberships){
            queueIds.add(member.GroupId);
        }

        return queueIds;
    }

    @AuraEnabled
    public static QueueStatus[] getQueueStatus(Id[] queueIds){
        Map<Id, QueueStatus> queueStatusById = new Map<Id, QueueStatus>();
        for(Group queue:[SELECT Id, Name FROM Group WHERE Id IN :queueIds]){
            queueStatusById.put(queue.Id, new QueueStatus(queue.Id, queue.Name));
        }

        AggregateResult[] queueItems = new AggregateResult[]{};
        AggregateResult[] messagingSessions = [SELECT COUNT(Id), MIN(CreatedDate), OwnerId, Owner.Name FROM MessagingSession WHERE OwnerId IN :queueIds GROUP BY OwnerId, Owner.Name];
        AggregateResult[] cases = [SELECT COUNT(Id), MIN(CreatedDate), OwnerId, Owner.Name FROM Case WHERE OwnerId IN :queueIds GROUP BY OwnerId, Owner.Name];
        AggregateResult[] chatTranscripts = [SELECT COUNT(Id), MIN(CreatedDate), OwnerId, Owner.Name FROM LiveChatTranscript WHERE OwnerId IN :queueIds GROUP BY OwnerId, Owner.Name];
        queueItems.addAll(messagingSessions);
        queueItems.addAll(cases);
        queueItems.addAll(chatTranscripts);

        for(AggregateResult result:queueItems){
            Id queueId = (String)result.get('OwnerId');
            Integer countWaiting = (Integer)result.get('expr0');
            Datetime oldestOpenTime = (Datetime)result.get('expr1');

            queueStatusById.get(queueId).addQueue(countWaiting, oldestOpenTime);
        }

        QueueStatus[] sortedQueueStatuses = queueStatusById.values();
        sortedQueueStatuses.sort();
        if(!sortedQueueStatuses.isEmpty()) return sortedQueueStatuses;
        return null;
    }


    private class QueueStatus implements Comparable {
        @AuraEnabled public Id queueId { get; private set; }
        @AuraEnabled public String queueName { get; private set; }
        @AuraEnabled public Integer countWaiting { get; private set;}
        private Datetime oldestOpenTime;
        @AuraEnabled public String longestWaitTime { get; private set;}

        public QueueStatus(Id queueId, String queueName){
            this.queueId = queueId;
            this.queueName = queueName;
            this.countWaiting = 0;
            this.longestWaitTime = '--';
        }

        public void addQueue(Integer countWaiting, Datetime oldestOpenTime){
            this.countWaiting += countWaiting;
            if(this.oldestOpenTime == null || this.oldestOpenTime > oldestOpenTime){
                this.oldestOpenTime = oldestOpenTime;
                Integer minutesSinceOpen = (Integer)(Datetime.now().getTime() - this.oldestOpenTime.getTime()) / 1000 / 60;
                Integer days = minutesSinceOpen / 60  / 24 ;
                Integer hours = (minutesSinceOpen - days * 60 * 24) / 60 ;
                Integer minutes = minutesSinceOpen - days * 60 * 24 - hours * 60 ;
                this.longestWaitTime = '';
                if(days > 0) longestWaitTime += days +' d, ';
                if(days > 0 || hours > 0) longestWaitTime += hours + ' h ';
                longestWaitTime += minutes + ' min';
            }
        }

        public Integer compareTo(Object compareTo) {
            QueueStatus compareToQueueStatus = (QueueStatus)compareTo;
            if(this.countWaiting == compareToQueueStatus.countWaiting) return 0;
            if(this.countWaiting > compareToQueueStatus.countWaiting) return -1;
            return 1;
        }
    }
}