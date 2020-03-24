/**
    Represents an attachment to a message
*/
global class MSG_Attachment {
    /**
        The name of the attachment
    */
    global String name{get;private set;}
    /**
        The content type of the attachment
    */
    global String contentType{get;private set;}
    /**
        The binary data of the attachment
    */
    global Blob data{get;private set;}
    /**
        Creates an attachment instance
        @param name The name of the attachment
        @param contentType The content type of the attachment
        @param data The binary data of the attachment
    */
    global MSG_Attachment(String name,String contentType,Blob data){
        this.name=name;
        this.contentType=contentType;
        this.data=data;
    }
}
