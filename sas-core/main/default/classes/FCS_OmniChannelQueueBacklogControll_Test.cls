/**
 * Created by anorell on 2020-04-29.
 */

@IsTest
private class FCS_OmniChannelQueueBacklogControll_Test {
    @IsTest
    static void shouldReturnQueueIdsBasedOnMembership() {
        User u = FCS_TestDataFactory.createUsers(1)[0];
        UserRole[] roles = [SELECT Id FROM UserRole];
        u.UserRoleId = roles[1].Id;
        update u;

        Group queue1 = new Group(Type = 'Queue', Name = 'Queue1');
        Group queue2 = new Group(Type = 'Queue', Name = 'Queue2');
        Group queue3 = new Group(Type = 'Queue', Name = 'Queue3');
        insert queue1;
        insert queue2;
        insert queue3;
        Group pg = new Group(Type = 'Regular', Name = 'PG');
        insert pg;
        insert new GroupMember(UserOrGroupId = pg.Id, GroupId = queue2.Id);

        GroupMember directMemberShip = new GroupMember(UserOrGroupId = u.Id, GroupId = queue1.Id);
        insert directMemberShip;
        GroupMember publicGroupMemberShip = new GroupMember(UserOrGroupId = u.Id, GroupId = pg.Id);
        insert publicGroupMemberShip;

        Id[] queueIds = FCS_OmniChannelQueueBacklogController.getQueueIds(u.Id);
        System.assertEquals(2, queueIds.size());

    }
}