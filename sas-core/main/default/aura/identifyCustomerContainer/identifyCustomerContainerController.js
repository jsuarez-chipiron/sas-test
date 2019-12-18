/**
 * @author Anton Norell
 * @date 2019-12-17
 * @description JS controller for Aura component used to wrap LWC to handle legacy methods
 */
({
  /**
   * Event handler for event fired from child LWC, requesting a refresh of a standard page.
   */
  refreshView: function(component, event) {
    $A.get('e.force:refreshView').fire();
    console.log('Fired event refreshView from Aura');
  },

  /**
   * Used to retrieve the current tab id of page where component is placed.
   */
  getEnclosingTabId : function(component, event, helper) {
    const workspaceAPI = component.find("workspace");
    workspaceAPI.getEnclosingTabId().then(function(tabId) {
      component.set("v.tabId", tabId);
      console.log('Enclosing tab id in Aura: ' + tabId);
    })
      .catch(function(error) {
        console.log('Error when getting enclosed tab id: ' + error);
      });
  }
});