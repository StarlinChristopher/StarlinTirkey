package com.example.app;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

public final class App {
    private App() {}

    public static void main(String[] args) throws IOException {
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8080"));
        HttpServer server = HttpServer.create(new InetSocketAddress("0.0.0.0", port), 0);
        Path webRoot = Path.of(System.getenv().getOrDefault(
                "WEB_ROOT", Path.of("web").toAbsolutePath().toString())).normalize();
        server.createContext("/health", exchange -> respond(exchange, 200,
                "application/json; charset=utf-8",
                "{\"status\":\"healthy\",\"service\":\"aws-devops-backend\",\"version\":\"1.0.0\"}".getBytes(StandardCharsets.UTF_8)));
        server.createContext("/", exchange -> {
            String requestPath = exchange.getRequestURI().getPath();
            String relativePath = requestPath.equals("/") ? "index.html" : requestPath.substring(1);
            Path file = webRoot.resolve(relativePath).normalize();
            if (!file.startsWith(webRoot) || !Files.isRegularFile(file)) {
                respond(exchange, 404, "text/plain; charset=utf-8", "Not found".getBytes(StandardCharsets.UTF_8));
                return;
            }
            String contentType = switch (file.getFileName().toString()) {
                case "index.html" -> "text/html; charset=utf-8";
                case "platform.css" -> "text/css; charset=utf-8";
                case "platform.js" -> "application/javascript; charset=utf-8";
                default -> "application/octet-stream";
            };
            respond(exchange, 200, contentType, Files.readAllBytes(file));
        });
        Runtime.getRuntime().addShutdownHook(new Thread(() -> server.stop(0)));
        server.start();
        System.out.println("Backend application started on port " + port);
    }

    private static void respond(com.sun.net.httpserver.HttpExchange exchange, int status,
            String contentType, byte[] body) throws IOException {
        exchange.getResponseHeaders().set("Content-Type", contentType);
        exchange.getResponseHeaders().set("X-Content-Type-Options", "nosniff");
        exchange.getResponseHeaders().set("Content-Security-Policy",
                "default-src 'self'; style-src 'self' https://fonts.googleapis.com; "
                        + "font-src https://fonts.gstatic.com; script-src 'self'; object-src 'none'; base-uri 'self'");
        exchange.sendResponseHeaders(status, body.length);
        try (var output = exchange.getResponseBody()) {
            output.write(body);
        }
    }
}
