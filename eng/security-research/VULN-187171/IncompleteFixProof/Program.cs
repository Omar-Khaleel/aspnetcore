using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;

var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.Cookie.Name = "OutputCacheMultiIdentityProof";
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
var identityOrder = Environment.GetEnvironmentVariable("IDENTITY_ORDER") ?? "unauth-first";

if (identityOrder is not ("unauth-first" or "auth-first"))
{
    throw new InvalidOperationException("IDENTITY_ORDER must be unauth-first or auth-first.");
}

app.UseRouting();

// This is the recommended safe ordering. The proof does not depend on putting
// OutputCache before Authentication or Authorization.
app.UseAuthentication();
app.UseAuthorization();
app.UseOutputCache();

app.MapGet("/login/{user}", async (HttpContext context, string user) =>
{
    if (user is not ("alice" or "bob"))
    {
        return Results.BadRequest("Only alice and bob are valid controlled identities.");
    }

    var authenticatedIdentity = new ClaimsIdentity(
        new[]
        {
            new Claim(ClaimTypes.Name, user),
            new Claim("account_id", $"account-{user}"),
        },
        CookieAuthenticationDefaults.AuthenticationScheme);

    var unauthenticatedIdentity = new ClaimsIdentity(
        new[] { new Claim("proof_identity", "unauthenticated-primary-candidate") });

    var principal = identityOrder == "unauth-first"
        ? new ClaimsPrincipal(new[] { unauthenticatedIdentity, authenticatedIdentity })
        : new ClaimsPrincipal(new[] { authenticatedIdentity, unauthenticatedIdentity });

    await context.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal);

    return Results.Text(
        $"SIGNED_IN={user};ORDER={identityOrder};" +
        $"PRIMARY_AUTH={principal.Identity?.IsAuthenticated};" +
        $"ANY_AUTH={principal.Identities.Any(identity => identity.IsAuthenticated)}");
}).AllowAnonymous();

app.MapGet("/private", (HttpContext context) =>
{
    var execution = Interlocked.Increment(ref privateExecutionCount);
    var authenticatedIdentity = context.User.Identities.FirstOrDefault(identity => identity.IsAuthenticated);
    var user = authenticatedIdentity?.Name ?? "anonymous";
    var account = authenticatedIdentity?.FindFirst("account_id")?.Value ?? "none";
    var primaryAuthenticated = context.User.Identity?.IsAuthenticated == true;
    var anyAuthenticated = context.User.Identities.Any(identity => identity.IsAuthenticated);
    var endpoint = context.GetEndpoint();
    var hasAuthorize = endpoint?.Metadata.GetMetadata<IAuthorizeData>() is not null;
    var hasAllowAnonymous = endpoint?.Metadata.GetMetadata<IAllowAnonymous>() is not null;

    context.Response.Headers["X-Handler-Execution-Count"] = execution.ToString();
    context.Response.Headers["X-Resolved-Authenticated-User"] = user;
    context.Response.Headers["X-Primary-Identity-Authenticated"] = primaryAuthenticated.ToString();
    context.Response.Headers["X-Any-Identity-Authenticated"] = anyAuthenticated.ToString();
    context.Response.Headers["X-Has-Authorize-Data"] = hasAuthorize.ToString();
    context.Response.Headers["X-Has-Allow-Anonymous"] = hasAllowAnonymous.ToString();

    return Results.Text(
        $"PRIVATE_USER={user};ACCOUNT={account};EXEC_COUNT={execution};" +
        $"PRIMARY_AUTH={primaryAuthenticated};ANY_AUTH={anyAuthenticated};" +
        $"AUTH_METADATA={hasAuthorize};ALLOW_ANON={hasAllowAnonymous};" +
        $"IDENTITY_COUNT={context.User.Identities.Count()}");
})
.RequireAuthorization()
.CacheOutput();

app.MapGet("/private-nocache", (HttpContext context) =>
{
    var authenticatedIdentity = context.User.Identities.FirstOrDefault(identity => identity.IsAuthenticated);
    var user = authenticatedIdentity?.Name ?? "anonymous";
    var account = authenticatedIdentity?.FindFirst("account_id")?.Value ?? "none";
    return Results.Text(
        $"NO_CACHE_USER={user};ACCOUNT={account};" +
        $"PRIMARY_AUTH={context.User.Identity?.IsAuthenticated == true};" +
        $"ANY_AUTH={context.User.Identities.Any(identity => identity.IsAuthenticated)}");
}).RequireAuthorization();

app.MapGet("/health", () => Results.Text($"ok;IDENTITY_ORDER={identityOrder}"))
    .AllowAnonymous();

app.Run();
