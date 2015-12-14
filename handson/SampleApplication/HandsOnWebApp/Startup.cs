using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(HandsOnWebApp.Startup))]
namespace HandsOnWebApp
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
        }
    }
}
