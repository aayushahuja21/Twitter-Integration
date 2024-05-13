public class TwitterController {
    //Static Variables...
    private static final String BASE_URL;
    private static final String CONSUMER_KEY;
    private static final String ACCESS_TOKEN;
    private static final String MEDIA_UPLOAD_URL;
    private static final String CONSUMER_SECRET_KEY;
    private static final String ACCESS_TOKEN_SECRET;
    
    //Http Methods...
    private static final String HTTP_GET = 'GET';
    private static final String HTTP_POST = 'POST';
    private static final String HTTP_DELETE = 'DELETE';
    
    static {
        Twitter_Credentials__c credentials = Twitter_Credentials__c.getInstance(UserInfo.getUserId());
        
        if(credentials != null) {
            BASE_URL = credentials.baseURLV2__c;
			MEDIA_UPLOAD_URL = credentials.uploadFileV1__c;
			CONSUMER_KEY = credentials.consumerKey__c;   
            ACCESS_TOKEN = credentials.accessToken__c;
            CONSUMER_SECRET_KEY = credentials.consumerSecretKey__c;    
            ACCESS_TOKEN_SECRET = credentials.accessTokenSecret__c;  
        }
    }
    
    //Generic Method for API Callouts....
    public static HttpResponse callTwitterAPI(String endpoint, String methodName, String tweetMessage, String mediaId, Blob blobMedia) {    
        if (CONSUMER_KEY == null || ACCESS_TOKEN == null || CONSUMER_SECRET_KEY == null || ACCESS_TOKEN_SECRET == null) {
            System.debug('Authentication issue, Value(s) are null');
            return null;
        }
        System.debug(tweetMessage);
        System.debug(mediaId);

        Http http = new Http();
        HttpRequest req = new HttpRequest();        
        req.setEndpoint(endpoint);
        req.setMethod(methodName);        
        
        if(methodName == HTTP_POST) {   
            if(blobMedia != NULL) {
                // Constructing the multipart/form-data request body
                String boundary = '----------------------------' + String.valueOf(System.currentTimeMillis());
                String requestBody = '--' + boundary + '\r\nContent-Disposition: form-data; name="media_data"; filename="media.jpg"\r\n' +
                                     'Content-Type: image/jpeg\r\n\r\n' + EncodingUtil.base64Encode(blobMedia) + '\r\n--' + boundary + '--';
                
                req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
                req.setBody(requestBody); 	
            }
            else {
                req.setHeader('Content-Type','application/json');
                
                String requestBody = mediaId == null ? '{"text":"'+ tweetMessage +'"}' : '{"text": "' + tweetMessage + '", "media": {"media_ids": ["' + mediaId + '"]}}';
                req.setBody(requestBody);                
            }
        }
        
        req = OAuth.signRequest(req, CONSUMER_KEY, ACCESS_TOKEN, CONSUMER_SECRET_KEY + '&' + ACCESS_TOKEN_SECRET);  
        return http.send(req);
    }
    
    // Method to POST Tweet using Media....
    @AuraEnabled
    public static String postMediaTweet(String tweetMessage, String blobMediaString) {  

        System.debug(tweetMessage);
        Blob blobMedia = EncodingUtil.base64Decode(blobMediaString);
        System.debug('blobMedia: '+blobMedia);
        String endpoint = MEDIA_UPLOAD_URL + 'media/upload.json';
        
        HttpResponse res = callTwitterAPI(endpoint, HTTP_POST, null, null, blobMedia);
        System.debug(res.getBody());
        
        if(res != null && res.getStatusCode() == 200) {
            Map<String, Object> deserialized = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
			String mediaId = (String)deserialized.get('media_id_string');
            
            return postTweet(tweetMessage, mediaId);
        }    
        return 'Error: '+res.getBody();    
    }
    
    // Method to POST Tweet ....
    @AuraEnabled
    public static String postTweet(String tweetMessage, String mediaId) { 
        System.debug(tweetMessage +':'+mediaId);

        String endpoint = BASE_URL + 'tweets';
        
        HttpResponse res = callTwitterAPI(endpoint, HTTP_POST, tweetMessage, mediaId, null);
        System.debug(res);
        
        if(res != null && res.getStatusCode() == 201) {
            System.debug(res.getBody());
            return res.getBody();
        }
        return 'Error: '+res.getBody();
    }
    
    // Method to DELETE Tweet using tweetId....
    @AuraEnabled
    public static String  deleteTweet(String tweetId) {  
        String endpoint = BASE_URL + 'tweets/' + tweetId;
        
        HttpResponse res = callTwitterAPI(endpoint, HTTP_DELETE, null, null, null);
        System.debug(res);
        
        if(res != null && res.getStatusCode() == 200) {
            System.debug(res.getBody());
            return String.valueOf(res.getStatusCode());
        }

        return 'Error: '+res.getBody();
    }
    
    //Method to get User details....
    @AuraEnabled
    public static String getUserDetails() {          
        String endpoint = BASE_URL + 'users/me';
        
        HttpResponse res = callTwitterAPI(endpoint, HTTP_GET, null, null, null);
        System.debug(res);
        
        if(res != null && res.getStatusCode() == 200) {
            System.debug(res.getBody());
            return res.getBody();
        }        

        return 'Error: '+res.getBody();
    }
}