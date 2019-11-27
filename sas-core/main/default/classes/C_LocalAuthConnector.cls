/**
 * @author Peter Södergren
 * @description Abstract class to enable per auth type connector to authenticate against the underlying system.
 */
global abstract class C_LocalAuthConnector {
    /**
     * Authenticates against the service
     * @param username The username to use when authenticating
     * @param password The password used when authenticating
     * @return The oauth access token
     */
    global abstract String authenticate(String username,String password, String param1, String param2);
}
