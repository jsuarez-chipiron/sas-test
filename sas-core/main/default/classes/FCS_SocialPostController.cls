public with sharing class FCS_SocialPostController {
    public List<SocialPost> socialPosts {get; private set;}

    public FCS_SocialPostController(ApexPages.StandardSetController controller) {
        Id id = (Id) ApexPages.currentPage().getParameters().get('id');
        if (id != null) {
            controller.setSelected(
                [SELECT Id, Name, OwnerId FROM SocialPost WHERE Id = :id]
            );
        }
        this.socialPosts = (List<SocialPost>) controller.getSelected();
    }

    public Pagereference save() {
        for(SocialPost sp : socialPosts) {
            sp.OwnerId = UserInfo.getUserId();
        }
        update socialPosts;
        return null;
    }
}
