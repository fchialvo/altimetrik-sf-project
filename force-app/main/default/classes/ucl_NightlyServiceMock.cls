@isTest
global class ucl_NightlyServiceMock implements HttpCalloutMock{
    
    global HttpResponse respond(HttpRequest request){
        HttpResponse response = new HttpResponse();
        response.setHeader('contentType', 'application/json');
        response.setBody('[{"AccountNumber":"9afccdd3-e7c4-4789-a465-1734886633d2","AccountName":"Centidel","AccountStatus":"Enabled","AsOfDate":"2/13/2019","Clients":[{"FirstName":"Foster","LastName":"Burn","Email":"fburn0@nydailynews.com","Phone":"425-154-5410","Address":"49018 Bashford Road","ClientNumber":"b4110a35-7ca3-4a53-8d94-ea78c5489052"}]}, {"AccountNumber": "123","AccountName": "Youfeed","AccountStatus": "Disabled","AsOfDate": "8/22/2019","Clients": [{"FirstName": "Olympie","LastName": "Gerraty","Email": "ogerraty0@dot.gov","Phone": "531-972-0115","Address": "22 Montana Circle","ClientNumber": "fe4eee39-0c70-4c6e-ba10-aa83e02ef4d6"}]}]');
        response.setStatusCode(200);
        return response;
    }
}