/**
 * Created by ssorberg on 2019-12-09.
 */

trigger SocialPostTrigger on SocialPost (before insert, after insert, before update ) {
    new FCS_SocialPostHandler().run();
}