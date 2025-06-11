using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Azure.Extensions.AspNetCore.Configuration.Secrets;

namespace RealTimeApp.Infrastructure.Data;

public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<ApplicationDbContext>
{
    public ApplicationDbContext CreateDbContext(string[] args)
    {
        var builder = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: true)
            .AddJsonFile("appsettings.Development.json", optional: true)
            .AddEnvironmentVariables();

        // Add Key Vault if configured
        var tempConfig = builder.Build();
        var keyVaultName = tempConfig["KeyVaultName"];
        if (!string.IsNullOrEmpty(keyVaultName))
        {
            var keyVaultUri = new Uri($"https://{keyVaultName}.vault.azure.net/");
            builder.AddAzureKeyVault(keyVaultUri, new DefaultAzureCredential());
        }

        var configuration = builder.Build();
        var connectionString = configuration["SqlConnectionString"] ?? configuration.GetConnectionString("SqlServer");
        Console.WriteLine($"Connection string: {connectionString}");
        
        var optionsBuilder = new DbContextOptionsBuilder<ApplicationDbContext>();
        optionsBuilder.UseSqlServer(connectionString, options =>
        {
            options.EnableRetryOnFailure();
        });

        return new ApplicationDbContext(optionsBuilder.Options);
    }
} 