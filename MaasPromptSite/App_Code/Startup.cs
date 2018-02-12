using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(MaasPromptSite.Startup))]
namespace MaasPromptSite
{
    public partial class Startup {
        public void Configuration(IAppBuilder app) {
            ConfigureAuth(app);
        }
    }
}
