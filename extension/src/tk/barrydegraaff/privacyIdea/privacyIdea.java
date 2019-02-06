/*

Copyright (C) 2019  Barry de Graaff

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see http://www.gnu.org/licenses/.

*/
package tk.barrydegraaff.privacyIdea;

import java.security.SecureRandom;
import java.util.Map;

import com.zimbra.common.service.ServiceException;
import com.zimbra.common.soap.Element;
import com.zimbra.cs.account.Account;
import com.zimbra.cs.account.Cos;
import com.zimbra.soap.DocumentHandler;
import com.zimbra.soap.ZimbraSoapContext;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.Properties;
import java.io.FileInputStream;
import java.io.InputStreamReader;

/*

Example request from the browser:

//list tokens:
      var soapDoc = AjxSoapDoc.create("privacyIdea", "urn:privacyIdea", null);
      var params = {
         soapDoc: soapDoc,
         asyncMode: true,
         callback:null
      };
      soapDoc.getMethod().setAttribute("action", "PIList");
      appCtxt.getAppController().sendRequest(params);


//delete token
      var soapDoc = AjxSoapDoc.create("privacyIdea", "urn:privacyIdea", null);
      var params = {
         soapDoc: soapDoc,
         asyncMode: true,
         callback:null
      };
      soapDoc.getMethod().setAttribute("action", "PIDelete");
      soapDoc.getMethod().setAttribute("serial", "TOTP0035F1C0");
      appCtxt.getAppController().sendRequest(params);


//init 2FA token
      var soapDoc = AjxSoapDoc.create("privacyIdea", "urn:privacyIdea", null);
      var params = {
         soapDoc: soapDoc,
         asyncMode: true,
         callback:null
      };
      soapDoc.getMethod().setAttribute("action", "PIInit");
      soapDoc.getMethod().setAttribute("zimbratokendescr", "set a description");
      appCtxt.getAppController().sendRequest(params);

//init Device passcode
      var soapDoc = AjxSoapDoc.create("privacyIdea", "urn:privacyIdea", null);
      var params = {
         soapDoc: soapDoc,
         asyncMode: true,
         callback:null
      };
      soapDoc.getMethod().setAttribute("action", "PIDeviceInit");
      soapDoc.getMethod().setAttribute("zimbratokendescr", "set a description");
      appCtxt.getAppController().sendRequest(params);



*/

public class privacyIdea extends DocumentHandler {
    public Element handle(Element request, Map<String, Object> context)
            throws ServiceException {
        try {
            ZimbraSoapContext zsc = getZimbraSoapContext(context);

            //Get the User Account and CoS
            Account acct = getRequestedAccount(zsc);
            String username = acct.getName();
            Cos cos = acct.getCOS();
            String COS = cos.getName();


            Element response = zsc.createElement(
                    "response"
            );

            Properties prop = new Properties();
            String apiURI = "";
            String token = "";
            String initJSON = "";
            String deviceJSON = "";
            Boolean accountname_with_domain = false;

            /*In the properties file you can set the following properties
             *
             * apiURI    - the url to the PrivacyIDEA instance e.g http://172.28.0.2:8000
             * token     - the admin token, you can get it using docker exec -it privacyidea bash /usr/bin/pi-manage api createtoken
             * initJSON  - the JSON string that holds the settings for creation of the token example:
             *             {"timeStep":30,"otplen":6,"genkey":true,"description":"zimbratokendescr","type":"totp","radius.system_settings":true,"2stepinit":false,"validity_period_start":"","validity_period_end":"","user":"zimbrauserdonotchangethis","realm":"zimbra"}
             * deviceJSON- the JSON string that holds the settings for creation of device/application passcodes:
             *             {"otpkey":"zimbradevicepasscode","description":"zimbratokendescr","type":"pw","radius.system_settings":true,"2stepinit":false,"validity_period_start":"","validity_period_end":"","user":"zimbrauserdonotchangethis","realm":"zimbra"}
             *             Please leave the zimbrauserdonotchangethis text in the JSON, as the extension will replace that with the username of the current zimbra user. (same for zimbratokendescr and zimbradevicepasscode)
             * accountname_with_domain - boolean, if set to false, the username will be passed to PrivacyIDEA excluding the domainname. Aka info@example.com will be looked up as info. When set to true, info@example.com needs to exist as a user in PrivacyIDEA.
             *
             *
             * In case you want/need a configuration per domain, you can add the properties by appending the domain name like so:
             * apiURI_example.com
             * token_example.com
             * initJSON_example.com
             * accountname_with_domain_example.com
             *
             * In case one of the properties is missing, the default config will be used (apiURI,token,initJSON etc).
             * It is OK to have one domain with it's own configuration and let all other domains use the default config (from apiURI,token,initJSON etc).
             *
             * */
            try {
                FileInputStream input = new FileInputStream("/opt/zimbra/lib/ext/zimbraprivacyidea/config.properties");
                prop.load(input);
                apiURI = prop.getProperty("apiURI_" + getDomainByEmail(username), prop.getProperty("apiURI"));
                token = prop.getProperty("token_" + getDomainByEmail(username), prop.getProperty("token"));
                initJSON = prop.getProperty("initJSON_" + getDomainByEmail(username), prop.getProperty("initJSON"));
                deviceJSON = prop.getProperty("deviceJSON_" + getDomainByEmail(username), prop.getProperty("deviceJSON"));
                accountname_with_domain = Boolean.parseBoolean(prop.getProperty("accountname_with_domain_" + getDomainByEmail(username), prop.getProperty("accountname_with_domain")));
                input.close();
            } catch (Exception ex) {
                ex.printStackTrace();
                return response.setText(ex.toString());
            }

            if (!accountname_with_domain) {
                username = username.substring(0, username.lastIndexOf('@'));
            }

            /*String apiURI = "http://zimbradev:8000";
            System.out.print(PIInit(apiURI, token, initJSON));
            System.out.print("\r\n");
            System.out.print(PIDelete(apiURI, token, "TOTP0000AC34", "spam.3apxi2niz7"));
            System.out.print("\r\n");
            System.out.print(PIList(apiURI, token, "spam.3apxi2niz7"));
             */


            switch (request.getAttribute("action")) {
                case "PIInit":
                    initJSON = initJSON.replace("zimbrauserdonotchangethis", username);
                    initJSON = initJSON.replace("zimbratokendescr", request.getAttribute("zimbratokendescr"));
                    response.setText(PIInit(apiURI, token, initJSON));
                    break;
                case "PIDeviceInit":
                    deviceJSON = deviceJSON.replace("zimbrauserdonotchangethis", username);
                    String devicePassCode = generateDevicePassCode();
                    deviceJSON = deviceJSON.replace("zimbradevicepasscode", devicePassCode);
                    deviceJSON = deviceJSON.replace("zimbratokendescr", request.getAttribute("zimbratokendescr"));
                    response.setText(PIDeviceInit(apiURI, token, deviceJSON));
                    break;
                case "PIList":
                    response.setText(PIList(apiURI, token, username));
                    break;
                case "PIDelete":
                    response.setText(PIDelete(apiURI, token, request.getAttribute("serial"), username));
                    break;
            }
            return (response);
        } catch (
                Exception e) {
            throw ServiceException.FAILURE(e.toString(), e);
        }

    }

    /*Initializes a new OTP code
     * */
    public String PIInit(String apiURI, String token, String dataString) {
        try {
            byte[] postData = dataString.getBytes(StandardCharsets.UTF_8);
            int postDataLength = postData.length;

            URL url = new URL(apiURI + "/token/init");

            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestProperty("PI-Authorization", token);
            connection.setRequestProperty("Content-Type", "application/application/json");
            connection.setDoOutput(true);
            connection.setUseCaches(false);
            connection.setInstanceFollowRedirects(true);
            connection.setRequestMethod("POST");
            connection.setRequestProperty("charset", "utf-8");
            connection.setRequestProperty("Content-Length", Integer.toString(postDataLength));
            try (DataOutputStream wr = new DataOutputStream(connection.getOutputStream())) {
                wr.write(postData);
            }

            String inputLine;
            StringBuffer response = new StringBuffer();

            if (connection.getResponseCode() == 200) {
                // get response stream
                BufferedReader in = new BufferedReader(
                        new InputStreamReader(connection.getInputStream()));
                // feed response into the StringBuilder
                while ((inputLine = in.readLine()) != null) {
                    response.append(inputLine);
                }
                in.close();
                // Start parsing
                JSONObject obj = new JSONObject(response.toString());
                JSONObject detail = obj.getJSONObject("detail");
                String qrCode = detail.getJSONObject("googleurl").getString("img");

                return qrCode;

            } else {
                BufferedReader in = new BufferedReader(
                        new InputStreamReader(connection.getErrorStream()));
                // feed response into the StringBuilder
                while ((inputLine = in.readLine()) != null) {
                    response.append(inputLine);
                }
                in.close();
                return response.toString();
            }

        } catch (Exception e) {
            e.printStackTrace();
            return e.toString();
        }
    }

    /*Initializes a new Device PassCode
     * */
    public String PIDeviceInit(String apiURI, String token, String dataString) {
        try {
            byte[] postData = dataString.getBytes(StandardCharsets.UTF_8);
            int postDataLength = postData.length;

            URL url = new URL(apiURI + "/token/init");

            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestProperty("PI-Authorization", token);
            connection.setRequestProperty("Content-Type", "application/application/json");
            connection.setDoOutput(true);
            connection.setUseCaches(false);
            connection.setInstanceFollowRedirects(true);
            connection.setRequestMethod("POST");
            connection.setRequestProperty("charset", "utf-8");
            connection.setRequestProperty("Content-Length", Integer.toString(postDataLength));
            try (DataOutputStream wr = new DataOutputStream(connection.getOutputStream())) {
                wr.write(postData);
            }

            String inputLine;
            StringBuffer response = new StringBuffer();
            if (connection.getResponseCode() == 200) {
                // get response stream
                BufferedReader in = new BufferedReader(
                        new InputStreamReader(connection.getInputStream()));
                // feed response into the StringBuilder
                while ((inputLine = in.readLine()) != null) {
                    response.append(inputLine);
                }
                in.close();

                return response.toString();

            } else {
                BufferedReader in = new BufferedReader(
                        new InputStreamReader(connection.getErrorStream()));
                // feed response into the StringBuilder
                while ((inputLine = in.readLine()) != null) {
                    response.append(inputLine);
                }
                in.close();
                return response.toString();
            }

        } catch (Exception e) {
            e.printStackTrace();
            return e.toString();
        }
    }

    /*List current OTP tokens for the user
     * */
    public String PIList(String apiURI, String token, String user) {
        try {
            URL url = new URL(apiURI + "/token/?user=" + user + "&pagesize=1000000");

            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestProperty("PI-Authorization", token);

            connection.setUseCaches(false);
            connection.setInstanceFollowRedirects(true);
            connection.setDoOutput(true);
            connection.setRequestMethod("GET");
            connection.connect();


            String inputLine;
            StringBuffer response = new StringBuffer();
            if (connection.getResponseCode() == 200) {
                // get response stream
                BufferedReader in = new BufferedReader(
                        new InputStreamReader(connection.getInputStream()));
                // feed response into the StringBuilder
                while ((inputLine = in.readLine()) != null) {
                    response.append(inputLine);
                }
                in.close();

                return response.toString();

            } else {
                BufferedReader in = new BufferedReader(
                        new InputStreamReader(connection.getErrorStream()));
                // feed response into the StringBuilder
                while ((inputLine = in.readLine()) != null) {
                    response.append(inputLine);
                }
                in.close();
                return response.toString();
            }

        } catch (Exception e) {
            e.printStackTrace();
            return e.toString();
        }
    }


    /*Delete an OTP token from the user
     * */
    public String PIDelete(String apiURI, String token, String serial, String user) {
        try {
            //verify the user tries to delete a token that they are assigned (aka they cannot delete someone else's token)
            String tokenList = PIList(apiURI, token, user);
            JSONObject obj = new JSONObject(tokenList);
            JSONObject result = obj.getJSONObject("result");
            JSONArray tokens = result.getJSONObject("value").getJSONArray("tokens");

            Boolean hasToken = false;

            for (int i = 0; i < tokens.length(); i++) {
                JSONObject otptoken = tokens.getJSONObject(i);
                if (serial.equals(otptoken.getString("serial"))) {
                    hasToken = true;
                    break;
                }
            }
            if (!hasToken) {
                return "Token cannot be found in your list of tokens.";
            }


            URL url = new URL(apiURI + "/token/" + serial);

            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestProperty("PI-Authorization", token);

            connection.setUseCaches(false);
            connection.setInstanceFollowRedirects(true);
            connection.setDoOutput(true);
            connection.setRequestMethod("DELETE");
            connection.connect();


            String inputLine;
            StringBuffer response = new StringBuffer();
            if (connection.getResponseCode() == 200) {
                // get response stream
                BufferedReader in = new BufferedReader(
                        new InputStreamReader(connection.getInputStream()));
                // feed response into the StringBuilder
                while ((inputLine = in.readLine()) != null) {
                    response.append(inputLine);
                }
                in.close();

                return response.toString();

            } else {
                BufferedReader in = new BufferedReader(
                        new InputStreamReader(connection.getErrorStream()));
                // feed response into the StringBuilder
                while ((inputLine = in.readLine()) != null) {
                    response.append(inputLine);
                }
                in.close();
                return response.toString();
            }

        } catch (Exception e) {
            e.printStackTrace();
            return e.toString();
        }
    }

    public String getDomainByEmail(final String email) {
        String domain = null;
        int index = -1;
        if ((index = email.indexOf("@")) > -1) {
            domain = email.substring(index + 1);
        }

        return domain.trim();
    }

    public static String generateDevicePassCode() {
        SecureRandom random = new SecureRandom();
        String dic = "ABCDEFGHKMNPQRSTUVWXYZabcdefghkmnpqrstuvwxyz123456789";
        String result = "";
        for (int i = 0; i < 16; i++) {
            int index = random.nextInt(dic.length());
            result += dic.charAt(index);
        }
        return result;
    }
}
