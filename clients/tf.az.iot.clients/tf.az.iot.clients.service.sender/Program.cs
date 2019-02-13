using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

using Microsoft.Azure.Devices;

using Newtonsoft.Json.Linq;

namespace tf.az.iot.clients.service
{
    class Program
    {
        private const string connectionStringTemplate = @"HostName={0}.azure-devices.net;SharedAccessKeyName=service;SharedAccessKey={1}";

        private const TransportType transportType = TransportType.Amqp;

        private static ServiceClient serviceClient;

        private static string deviceId;

        private static int counter;

        private static Timer timer;

        private static void Main(string[] args)
        {
            var settings = JObject.Parse(File.ReadAllText("env.vars"));
            var connectionString = string.Format(connectionStringTemplate, settings["iot"]["name"], settings["iot"]["service_sap"]);
            deviceId = settings["iot"]["device"]["id"].ToString();

            serviceClient = ServiceClient.CreateFromConnectionString(connectionString, transportType);

            timer = new Timer(async state => await InvokeMethod(), null, 10_000, 10_000);

            Console.WriteLine("Press ENTER to stop SERVICE SENDER simulator");
            Console.ReadLine();

            timer.Dispose();
        }

        private static async Task InvokeMethod()
        {
            var request = $"{{ \"counter\": \"{++counter}\", \"at\": \"{DateTime.UtcNow}\" }}";
            Console.WriteLine($"Sending {request}");

            var c2dMethod = new CloudToDeviceMethod("cloud-device-connectivity", new TimeSpan(0, 0, 30));

            c2dMethod.SetPayloadJson(request);
            await serviceClient.InvokeDeviceMethodAsync(deviceId, c2dMethod);
        }
    }
}
