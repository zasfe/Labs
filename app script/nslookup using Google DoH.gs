/**
 * nslookup using Google DoH (DNS over HTTPS) API.
 *
 * https://medium.com/@aimhuge/reverse-dns-lookup-in-google-sheets-234c75966e55
 * 
 * @param {"google.com"} name    A well-formed domain name to resolve.
 * @param {"A"} type           Type of data to be returned, such as A, AAA, MX, NS...
 * @return {String}            Resolved IP address, or list of addresses separated by new lines
 * @customfunction
 */
function NSLookup(name,type) {
  var url = "https://dns.google.com/resolve?name=" + name + "&type=" + type;
  var response = UrlFetchApp.fetch(url);
  var responseCode = response.getResponseCode();
  if (responseCode !== 200) {
    throw new Error( responseCode + ": " + response.message );
  }
  var responseText = response.getContentText(); // Get the response text
  var json = JSON.parse(responseText); // Parse the JSON text
  var answers = json.Answer.map(function(ans) {
    return ans.data
  }).join('\n'); // Get the values
  return answers;
}
/**
 * reverse lookup using Google DoH (DNS over HTTPS) API.
 *
 * @param {"1.1.1.1"} ip    An ip address to lookup.
 * @return {String}         Resolved Fully Qualified Domain Name
 * @customfunction
 */
function reverseLookup(ip) {
  ip = ip.split(".").reverse().join(".")
  
  var url = "https://dns.google.com/resolve?name=" + ip + ".in-addr.arpa&type=PTR";
  var response = UrlFetchApp.fetch(url);
  var responseCode = response.getResponseCode();
  if (responseCode !== 200) {
    throw new Error( responseCode + ": " + response.message );
  }
  var responseText = response.getContentText(); // Get the response text
  var json = JSON.parse(responseText); // Parse the JSON text
  try{
    return json.Answer ? json.Answer[0].data : "no data" ;
}catch(err){
    return "no data: " + err ;
  }
}
/**
 * reverse lookup using Google DoH (DNS over HTTPS) API.
 *
 * @param {"1.1.1.1\n2.2.2.2"} ip    A new line separated list of IPs
 * @return {String}         Resolved List of Fully Qualified Domain Names
 * @customfunction
 */
function reverseLookups(ip){
  ips = ip.split('\n')
result = ips.map(function(ip) {
    var res = reverseLookup(ip);
    return res || "no data"
  }).join('\n');
  
  return result;
}
