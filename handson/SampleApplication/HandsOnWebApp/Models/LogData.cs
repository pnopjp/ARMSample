using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web;

namespace HandsOnWebApp.Models
{
    public class LogData
    {
        public int ID { get; set; }
        public DateTimeOffset Time { get; set; }
        public string Message { get; set; }
    }

    public class LogDataDbContext : DbContext
    {
        public DbSet<LogData> Logs { get; set; }
    }
}