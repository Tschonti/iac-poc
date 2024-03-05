param location string = resourceGroup().location
param apimServiceName string = 'wikimedia'
param github_pat string

resource apiManagementInstance 'Microsoft.ApiManagement/service@2020-12-01' = {
  name: apimServiceName
  location: location
  sku: {
    capacity: 0
    name: 'Consumption'
  }
  properties: {
    virtualNetworkType: 'None'
    publisherEmail: 'feketesamu@gmail.com'
    publisherName: 'feketesamu'
  }
}

resource api 'Microsoft.ApiManagement/service/apis@2019-12-01' = {
  parent: apiManagementInstance
  name: 'on-this-day'
  properties: {
    displayName: 'on-this-day'
    serviceUrl: 'https://api.wikimedia.org/feed/v1/wikipedia/en/onthisday/'
    path: '/selected'
    protocols: [ 'https' ]
    subscriptionRequired: false
  }
}

resource symbolicname 'Microsoft.ApiManagement/service/apis/operations@2023-05-01-preview' = {
  name: 'get-one-event'
  parent: api
  properties: {
    displayName: 'get-one-event'
    method: 'GET'
    urlTemplate: '/{month}/{day}'
    responses: [
      {
        statusCode: 200
        description: 'Successful response'
      }
    ]
    templateParameters: [
      {
        name: 'month'
        type: 'string'
        required: true
      }
      {
        name: 'day'
        type: 'string'
        required: true
      }
    ]
    policies: '''
      <outbound>
          <base />
          <choose>
              <when condition="@(context.Response.StatusCode == 200)">
                  <set-body>@{
                          var responseBody = context.Response.Body.As<JObject>();
                          var selectedArray = responseBody["selected"] as JArray;
                          var first = selectedArray.First() as JObject;
                          var newResponse = new JObject(new JProperty("event", first["text"]));
                          return newResponse.ToString();
                      }</set-body>
              </when>
          </choose>
      </outbound>
    '''
  }
}

resource staticwebapp 'Microsoft.Web/staticSites@2022-09-01' = {
  name: 'onthisday-fe'
  location: location
  sku: {
    name: 'F1'
    tier: 'Free'
  }
  properties: {
    repositoryToken: github_pat
    buildProperties: {
      appArtifactLocation: 'build'
      appLocation: '/'
    }
    repositoryUrl: 'https://github.com/Tschonti/iac-poc'
    provider: 'GitHub'
  }
}
