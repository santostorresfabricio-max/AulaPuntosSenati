using System.Text.Json.Serialization;
using AulaPuntos.Api.Data;
using AulaPuntos.Api.Services;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<AulaPuntosDbContext>(opt =>
    opt.UseSqlServer(builder.Configuration.GetConnectionString("AulaPuntos")));

builder.Services.AddScoped<AcademicRulesService>();
builder.Services.AddScoped<SyncService>();

builder.Services.AddControllers()
    .AddJsonOptions(o => o.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));

builder.Services.AddOpenApi();

// La app Flutter (web/desktop) consume la API desde otro origen durante el desarrollo.
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();

    // Aplica migraciones automáticamente en desarrollo.
    using var scope = app.Services.CreateScope();
    scope.ServiceProvider.GetRequiredService<AulaPuntosDbContext>().Database.Migrate();
}

app.UseHttpsRedirection();
app.UseCors();
app.MapControllers();

app.Run();
