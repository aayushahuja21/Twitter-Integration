public class OAuth {
    
    public static HttpRequest signRequest(HttpRequest req, String consumerKey, String oauthToken, String consumerSecret) {
        String nonce     = String.valueOf(Crypto.getRandomLong());
        String timestamp = String.valueOf(DateTime.now().getTime() / 1000);
        Map<String,String> parameters = new Map<String,String>();
        parameters.put('oauth_consumer_key', consumerKey);
        if(oauthToken != null){
            parameters.put('oauth_token',oauthToken);
        }
        parameters.put('oauth_signature_method','HMAC-SHA1');
        parameters.put('oauth_timestamp', timestamp);
        parameters.put('oauth_nonce', nonce);
        parameters.put('oauth_version', '1.0');
        
        String signature = generateSignature(req,consumerSecret,parameters);
        String header = generateHeader(signature, parameters);
        req.setHeader('Authorization', header);
        return req;
    }
    
    private static String generateHeader(String signature, Map<String,String> parameters) {
        String header = 'OAuth ';
        for (String key : parameters.keySet()) {
            header = header+key+'="'+parameters.get(key)+'",';
        }
        return header+'oauth_signature="'+signature+'"';
    }
    
    private static String generateSignature(HttpRequest req, String consumerSecret, Map<String,String> parameters) {
        String s = createBaseString(parameters,req);
        Blob sig = Crypto.generateMac(
            'HmacSHA1'
            , Blob.valueOf(s)
            , Blob.valueOf(consumerSecret)
        );
        return EncodingUtil.urlEncode(EncodingUtil.base64encode(sig), 'UTF-8');
    }
    
    private static String createBaseString(Map<String,String> oauthParams, HttpRequest req) {
        Map<String,String> p = oauthParams.clone();
        if(req.getMethod().equalsIgnoreCase('post') && req.getBody()!=null &&
           req.getHeader('Content-Type')=='application/json') {
               p.putAll(getUrlParams(req.getBody()));
           }
        String host = req.getEndpoint();
        Integer n = host.indexOf('?');
        if(n>-1) {
            p.putAll(getUrlParams(host.substring(n+1)));
            host = host.substring(0,n);
        }
        List<String> keys = new List<String>();
        keys.addAll(p.keySet());
        keys.sort();
        String s = keys.get(0)+'='+p.get(keys.get(0));
        for(Integer i=1;i<keys.size();i++) {
            s = s + '&' + keys.get(i)+'='+p.get(keys.get(i));
        }
        
        // According to OAuth spec, host string should be lowercased, but Google and LinkedIn
        // both expect that case is preserved.
        return req.getMethod().toUpperCase()+ '&' +
            EncodingUtil.urlEncode(host, 'UTF-8') + '&' +
            EncodingUtil.urlEncode(s, 'UTF-8');
    }
    
    private static Map<String,String> getUrlParams(String value) {
        
        Map<String,String> res = new Map<String,String>();
        if(value==null || value=='') {
            return res;
        }
        for(String s : value.split('&')) {
            System.debug('getUrlParams: '+s);
            List<String> kv = s.split('=');
            if(kv.size()>1) {
                // RFC 5849 section 3.4.1.3.1 and 3.4.1.3.2 specify that parameter names
                // and values are decoded then encoded before being sorted and concatenated
                // Section 3.6 specifies that space must be encoded as %20 and not +
                String encName = EncodingUtil.urlEncode(EncodingUtil.urlDecode(kv[0], 'UTF-8'), 'UTF-8').replace('+','%20');
                String encValue = EncodingUtil.urlEncode(EncodingUtil.urlDecode(kv[1], 'UTF-8'), 'UTF-8').replace('+','%20');
                System.debug('getUrlParams:  -> '+encName+','+encValue);
                res.put(encName,encValue);
            }
        }
        return res;
    }
}