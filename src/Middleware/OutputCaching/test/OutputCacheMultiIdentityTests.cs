// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

using System.Net.Http;
using System.Security.Claims;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Net.Http.Headers;

namespace Microsoft.AspNetCore.OutputCaching.Tests;

public class OutputCacheMultiIdentityTests
{
    [Fact]
    public async Task AuthenticatedSecondaryIdentityIsNotCached()
    {
        var endpointHitCount = 0;
        var builder = new HostBuilder()
            .ConfigureWebHost(webHostBuilder =>
            {
                webHostBuilder
                    .UseTestServer()
                    .ConfigureServices(services =>
                    {
                        services.AddOutputCache(options =>
                        {
                            options.BasePolicies = [new OutputCachePolicyBuilder().Build()];
                        });
                    })
                    .Configure(app =>
                    {
                        app.Use((context, next) =>
                        {
                            if (context.Request.Headers.TryGetValue("name", out var name))
                            {
                                var unauthenticatedIdentity = new ClaimsIdentity(
                                    new[] { new Claim("proof_identity", "unauthenticated-primary") });
                                var authenticatedIdentity = new ClaimsIdentity(
                                    new[] { new Claim(ClaimTypes.Name, name.ToString()) },
                                    authenticationType: "custom");

                                context.User = new ClaimsPrincipal(
                                    new[] { unauthenticatedIdentity, authenticatedIdentity });

                                Assert.False(context.User.Identity?.IsAuthenticated);
                                Assert.True(context.User.Identities.Any(identity => identity.IsAuthenticated));
                            }

                            return next(context);
                        });

                        app.UseOutputCache();

                        app.Run(async context =>
                        {
                            endpointHitCount++;
                            var authenticatedIdentity = context.User.Identities
                                .FirstOrDefault(identity => identity.IsAuthenticated);
                            await context.Response.WriteAsync(authenticatedIdentity?.Name ?? "anonymous");
                        });
                    });
            });

        using var host = builder.Build();
        await host.StartAsync();

        using var server = host.GetTestServer();
        using var client = server.CreateClient();

        var aliceResponse = await client.SendAsync(
            new HttpRequestMessage(HttpMethod.Get, "") { Headers = { { "name", "alice" } } });
        var bobResponse = await client.SendAsync(
            new HttpRequestMessage(HttpMethod.Get, "") { Headers = { { "name", "bob" } } });

        Assert.Equal("alice", await aliceResponse.Content.ReadAsStringAsync());
        Assert.Equal("bob", await bobResponse.Content.ReadAsStringAsync());
        Assert.False(aliceResponse.Headers.Contains(HeaderNames.Age));
        Assert.False(bobResponse.Headers.Contains(HeaderNames.Age));
        Assert.Equal(2, endpointHitCount);
    }
}
