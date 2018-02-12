using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(MaasPrompt.Startup))]
namespace MaasPrompt
{
    public partial class Startup {
        public void Configuration(IAppBuilder app) {
            ConfigureAuth(app);
        }
    }
}
