using HandsOnWebApp.Models;
using System.Linq;
using System.Web.Mvc;

namespace HandsOnWebApp.Controllers
{
    public class HomeController : Controller
    {
        private LogDataDbContext db = new LogDataDbContext();

        public ActionResult Index()
        {
            db.Logs.Add(new LogData
            {
                Message = string.Format("{0} にアクセスがありました", System.Environment.MachineName),
                Time = System.DateTimeOffset.UtcNow.AddHours(9)
            });
            db.SaveChanges();
            return View(db.Logs.OrderByDescending(x => x.ID).Take(15).ToList());
        }

        public ActionResult Add()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Add(string message)
        {
            try
            {
                if (!string.IsNullOrWhiteSpace(message))
                {
                    db.Logs.Add(new LogData
                    {
                        Message = string.Format("{0}", message),
                        Time = System.DateTimeOffset.UtcNow.AddHours(9)
                    });
                    db.SaveChanges();
                }
                return RedirectToAction("Index");
            }
            catch
            {
                return View();
            }
        }
    }
}
