/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description TODO
*/

public class IRR_ACT_StaticInput {

    public static IRR_MOD_FlowVariables actionOutput;

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Returns the static action output variable. This variable is required to be set.
     *          *Warning* This action requires Apex setup and is not bulkified.
     *
     * @return Action Output variable
     */
    @InvocableMethod
    public static List<IRR_MOD_FlowVariables> getActionOutput() {
        return new List<IRR_MOD_FlowVariables>{actionOutput};
    }
    /*@InvocableMethod
    public static List<StaticOutput> deserializeObject() {
        StaticOutput output = new StaticOutput();
        output.flowVariables = actionOutput;
        return new List<StaticOutput>{output};
    }

    public class StaticOutput {
        @InvocableVariable
        public List<IRR_MOD_FlowVariables> flowVariables;
    }*/

}