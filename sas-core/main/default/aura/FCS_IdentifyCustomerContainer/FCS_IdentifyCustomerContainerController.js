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
});