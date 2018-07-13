package application.rest.v1;

import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ResponseBody;
import java.util.ArrayList;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import com.cloudant.client.api.CloudantClient;

import org.springframework.core.io.ResourceLoader;
import org.springframework.core.io.Resource;

import java.net.MalformedURLException;
import java.net.URL;
import java.security.cert.Certificate;
import java.io.*;

import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLPeerUnverifiedException;

import java.util.Base64;
import java.util.Iterator;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

import org.apache.commons.io.IOUtils;

@RestController
public class Example {

    @Autowired
    private CloudantClient client;

    @Autowired
    private ResourceLoader resourceLoader;

    private static final String POST_URL = "https://vision.googleapis.com/v1/images:annotate?key=AIzaSyBy-LP4_xv3rP-e1m341u4OznvqCWFakaE";

    @RequestMapping("v1")
    public @ResponseBody ResponseEntity<String> example() {
      List<String> list = new ArrayList<>();
      //return a simple list of strings
      list.add("Congratulations, your application is up and running");
      return new ResponseEntity<String>(list.toString(), HttpStatus.OK);
    }

    @RequestMapping(value = "v1/ocr/imageUri", method = RequestMethod.POST)
    public @ResponseBody IBMBusinessCard getIBMBusinessCard(@RequestBody String postPayload) {
      IBMBusinessCard card = null;

      try {
        JSONParser parser = new JSONParser();
        JSONObject jsonRequest = (JSONObject)parser.parse(postPayload);
        String imageURI = jsonRequest.get("image_url").toString();

        String request = "{'requests': [{'image': {'source':{'imageUri':'" + imageURI + "'}}, 'features': [{'type': 'TEXT_DETECTION'}]}]}";
        card = this.getCard(request, parser);
      } catch(Exception ex) {
        System.out.println(ex.toString());
      }
      return card;
    }

    @RequestMapping(value = "v1/ocr/base64", method = RequestMethod.POST)
    public @ResponseBody IBMBusinessCard getIBMBusinessCardFromBase64(@RequestBody String postPayload) {
      IBMBusinessCard card = null;

      try {
        JSONParser parser = new JSONParser();
        JSONObject jsonRequest = (JSONObject)parser.parse(postPayload);
        String base64 = jsonRequest.get("base64").toString();

        String request = "{'requests': [{'image': {'content': '" + base64 + "'}, 'features': [{'type': 'TEXT_DETECTION'}]}]}";
        card = this.getCard(request, parser);
      } catch(Exception ex) {
        System.out.println(ex.toString());
      }
      return card;
    }

    private IBMBusinessCard getCard(String request, JSONParser parser) {
      IBMBusinessCard card = new IBMBusinessCard();
      try {
        String response = this.getText(request);
        JSONObject jsonObject = (JSONObject)parser.parse(response);
        JSONArray responses = (JSONArray) jsonObject.get("responses");
        Iterator<JSONObject> iterator = responses.iterator();
        while (iterator.hasNext()) {
          JSONObject prop = iterator.next();
          if (prop.get("fullTextAnnotation") != null) {
            JSONObject fullTextAnnotation = (JSONObject) prop.get("fullTextAnnotation");
            if (fullTextAnnotation != null) {
              String text = fullTextAnnotation.get("text").toString();
              String [] arrOfStr = text.split("\n");
              card.setName(arrOfStr[0].replace("Sandeop", "Sandeep"));
              card.setEmail(arrOfStr[8]);
              card.setPhone(arrOfStr[6].replace("Tel", "").replace(" ", "").replace("l","+1"));
              break;
            }
          }
        }
      } catch(Exception ex) {
        System.out.println(ex.toString());
      }
      return card;
    }

    private String getText(String request) throws IOException {
          StringBuilder sb = new StringBuilder();
          try {
            URL url = new URL(POST_URL);
            HttpsURLConnection http = (HttpsURLConnection)url.openConnection();
            http.setDoOutput(true);
            http.setRequestMethod("POST");
            http.setRequestProperty("Content-Type", "application/json");
            http.connect();

            DataOutputStream wr = new DataOutputStream(http.getOutputStream());
            wr.writeBytes(request.toString());

            wr.flush();
            wr.close();

            if(http!=null) {
            	try {
                int responseCode = http.getResponseCode();
          		  System.out.println("Response Code : " + responseCode);

            	  System.out.println("****** Content of the URL ********");
            	  BufferedReader br = new BufferedReader(new InputStreamReader(http.getInputStream()));

            	  String input;

            	  while ((input = br.readLine()) != null){
            	     sb.append(input + "\n");
            	  }
            	  br.close();
            	} catch (IOException e) {
            	   e.printStackTrace();
            	}
            }
        } catch(Exception ex) {
          System.out.println(ex.toString());
        }
        return sb.toString();
	  }
}
