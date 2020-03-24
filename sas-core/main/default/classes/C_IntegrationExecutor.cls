/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Contains common functionality for Integration Executor implementations.
*/

public class C_IntegrationExecutor {

    public enum Method { GET, POST }

    public interface IConstructable {
        C_IIntegrationExecutor construct(String baseUrl, Map<String, String> requestHeaders);
    }
}