using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;

var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.Cookie.Name = "OutputCacheVersionProof";
        options.Cookie.HttpOnly = true;
        options.Cookie.SameSite = SameSiteMode.Strict;
        options.Events.OnRedirectToLogin = context =>
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            return Task.CompletedTask;
        };
        options.Events.OnRedirectToAccessDenied = context =>
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            return Task.CompletedTask;
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddOutputCache();

var app = builder.Build();
var privateExecutionCount = 0;

app.UseRouting();

// Intentionally reproduces the affected ordering from VULN-187171.
// No custom OutputCache policy and no public Cache-Control header are used.
app.UseOutputCache();
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/login/{user}", async (HttpContext context, string user) =>
{
    if (user is not ("alice" or "bob"))
    {
        return Results.BadRequest("Only alice and bob are valid controlled test identities.");
    }

    var claims = new[]
    {
        new Claim(ClaimTypes.Name, user),
        new Claim("account_id", $"account-{user}"),
    };

    var principal = new ClaimsPrincipal(
        new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme));

    await context.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal);
    return Results.Text($"SIGNED_IN={user};ACCOUNT=account-{user}");
}).AllowAnonymous();

app.MapGet("/private", (HttpContext context) =>
{
    var execution = Interlocked.Increment(ref privateExecutionCount);
    var user = context.User.Identity?.Name ?? "anonymous";
    var account = context.User.FindFirst("account_id")?.Value ?? "none";
    var endpoint = context.GetEndpoint();
    var hasAuthorize = endpoint?.Metadata.GetMetadata<IAuthorizeData>() is not null;
    var hasAllowAnonymous = endpoint?.Metadata.GetMetadata<IAllowAnonymous>() is not null;

    context.Response.Headers["X-Handler-Execution-Count"] = execution.ToString();
    context.Response.Headers["X-Authenticated-User"] = user;
    context.Response.Headers["X-Has-Authorize-Data"] = hasAuthorize.ToString();
    context.Response.Headers["X-Has-Allow-Anonymous"] = hasAllowAnonymous.ToString();

    return Results.Text(
        $"PRIVATE_USER={user};ACCOUNT={account};EXEC_COUNT={execution};" +
        $"AUTH_METADATA={hasAuthorize};ALLOW_ANON={hasAllowAnonymous}");
})
.RequireAuthorization()
.CacheOutput();

app.MapGet("/private-nocache", (HttpContext context) =>
{
    var user = context.User.Identity?.Name ?? "anonymous";
    var account = context.User.FindFirst("account_id")?.Value ?? "none";
    return Results.Text($"NO_CACHE_USER={user};ACCOUNT={account}");
}).RequireAuthorization();

app.MapGet("/health", () => Results.Text("ok")).AllowAnonymous();

app.Run();
