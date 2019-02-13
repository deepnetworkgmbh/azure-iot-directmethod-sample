using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;

using Microsoft.Azure.Devices.Client;

using Newtonsoft.Json.Linq;

namespace tf.az.iot.clients.device
{
    internal class Program
    {
        private const TransportType transportType = TransportType.Amqp;

        private static int Main(string[] args)
        {
            var settings = JObject.Parse(File.ReadAllText("env.vars"));
            var deviceConnectionString = settings["iot"]["device"]["connection_string"].ToString();
            var deviceClient = DeviceClient.CreateFromConnectionString(deviceConnectionString, transportType);

            if (deviceClient == null)
            {
                Console.WriteLine("Failed to create DeviceClient!");
                return 1;
            }

            deviceClient.SetMethodHandlerAsync("cloud-device-connectivity", Handler, null).Wait();

            Console.WriteLine("Press ENTER to stop DEVICE simulator");
            Console.ReadLine();

            return 0;
        }

        private static Task<MethodResponse> Handler(MethodRequest methodRequest, object userContext)
        {
            var data = methodRequest.DataAsJson;

            var response = $"{{ \"request\": {data}, \"at\": \"{DateTime.UtcNow}\" }}";
            Console.WriteLine($"Sending {response}");

            return Task.FromResult(new MethodResponse(Encoding.ASCII.GetBytes(response), 200));
        }
    }
}
