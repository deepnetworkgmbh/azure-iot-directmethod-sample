using System;
using System.IO;

using Microsoft.Azure.EventHubs;
using Microsoft.Azure.EventHubs.Processor;

using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace tf.az.iot.clients.service.listener
{
    class Program
    {
        private static string storageConnectionStringTemplate = @"DefaultEndpointsProtocol=https;AccountName={0};AccountKey={1};EndpointSuffix=core.windows.net";
        private static string eventHubConnectionStringTemplate = @"Endpoint={0};SharedAccessKeyName=service;SharedAccessKey={1};EntityPath={2}";

        private static void Main(string[] args)
        {
            var settings = JObject.Parse(File.ReadAllText("env.vars"));

            var storageConnectionString = string.Format(storageConnectionStringTemplate, settings["storage"]["name"], settings["storage"]["sak"]);
            var eventHubConnectionString = string.Format(eventHubConnectionStringTemplate, settings["iot"]["eh_endpoint"], settings["iot"]["service_sap"], settings["iot"]["name"]);

            var eventProcessorHost = new EventProcessorHost(
                settings["iot"]["name"].ToString(),
                PartitionReceiver.DefaultConsumerGroupName,
                eventHubConnectionString,
                storageConnectionString,
                "event-processor");

            eventProcessorHost.RegisterEventProcessorAsync<SimpleEventProcessor>().Wait();


            Console.WriteLine("Press ENTER to stop SERVICE LISTENER simulator");
            Console.ReadLine();
        }
    }
}
