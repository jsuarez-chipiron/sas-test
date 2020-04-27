/**
 * Created by anorell on 2020-04-26.
 */

({


  registerUtilityClickHandler: function(component, event, helper){
    let utilityBarAPI = component.find("utilitybar");
    let eventHandler = function(response){
      console.log(response);
    };

    utilityBarAPI.onUtilityClick({
      eventHandler: eventHandler
    }).then(function(result){
      console.log(result);
    }).catch(function(error){
      console.log(error);
    });
  }
});