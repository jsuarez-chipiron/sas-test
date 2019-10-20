/**
    Utility class containing utility methods shared by multiple classes
*/
public with sharing class C_Util {
    /**
        Cached value for the organization record
    */
    static Organization org;
    /**
        The UUID of the transaction
    */
    static String uuid;

    /**
        Retrieves the organization record into the cache
    */
    private static void getOrg(){
        org = [SELECT Id,Name,InstanceName,IsSandbox FROM Organization];
    }
    /**
        Return whether the current environment is a sandbox, i.e. not a production ord
        @return Whether the current org is a sandbox org
    */
    public static Boolean isSandbox(){
        if(org==null)getOrg();
        return org.IsSandbox;
    }

    /**
        Retireves the UUID generated for this transaction
        THh UUID is generated upon the first call of the method in the transaction
        @see generateUUID for details on the UUID
        @return The transaction UUID
    */
    public static String getUUID(){
        return uuid!=null ? uuid : (uuid = generateUUID());
    }
    
    /**
        Generates a universally unique identifier using crypto random integers
        The method generates a UUID of version 4
        The UUID is a 128 bt Id in the hex string with in the following format
        xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        @return The generated UUID
    */
    public static String generateUUID(){
        Integer i1 = Crypto.getRandomInteger();
        Integer i2 = Crypto.getRandomInteger();
        Integer i3 = Crypto.getRandomInteger();
        Integer i4 = Crypto.getRandomInteger();
        Integer[] chars = new Integer[36];
        Integer offset = 0;
        for(Integer i=0;i<8;i++){
            Integer sh = i*4;
            if(i>=2 && i<=5){
                chars[sh+offset]=45;
                offset++;
            }
            Integer s1 = (i1 >> sh) & 15;
            Integer s2 = (i2 >> sh) & 15;
            Integer s3 = (i3 >> sh) & 15;
            Integer s4 = (i4 >> sh) & 15;
            //Set version number 4
            if(i==3)s1 = 4;
            //Setting variant
            if(i==4)s1 = 8 | (s1 & 3);
            Integer idx = sh+offset;
            chars[idx] = s1 + (s1 < 10 ? 48 : 87);
            chars[idx+1] = s2 + (s2 < 10 ? 48 : 87);
            chars[idx+2] = s3 + (s3 < 10 ? 48 : 87);
            chars[idx+3] = s4 + (s4 < 10 ? 48 : 87);
        }
        return String.fromCharArray(chars);
    }
}
