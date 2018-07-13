package GoogleSearch.search;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public class webSearchEngine {


	public void search(String searchString) throws Exception{
		String key="AIzaSyDWXpb-DsxyXIUNua_G3f-dFq91aiKxwYA";
		URL url = new URL(
				"https://www.googleapis.com/customsearch/v1?key="+key+ "&cx=007015098947722202970:3rtfouasqfq&q="+ searchString + "&alt=json");
		HttpURLConnection conn = (HttpURLConnection) url.openConnection();
		conn.setRequestMethod("GET");
		conn.setRequestProperty("Accept", "application/json");
		BufferedReader br = new BufferedReader(new InputStreamReader((conn.getInputStream())));

		String output;
		System.out.println("Output from Server .... \n");
		while ((output = br.readLine()) != null) {

			if(output.contains("\"link\": \"")){                
				String link=output.substring(output.indexOf("\"link\": \"")+("\"link\": \"").length(), output.indexOf("\","));
				System.out.println(link);       //Will print the google search links
			}     
		}
		conn.disconnect();
	}


	public static void main(String[] args) throws Exception {
		
		webSearchEngine test = new webSearchEngine();
		test.search("sandeep+singhal");

	}

}
