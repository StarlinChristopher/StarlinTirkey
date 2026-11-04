package com.example.app;

import java.net.HttpURLConnection;
import java.net.URL;

public final class HealthCheck {
    private HealthCheck() {}

    public static void main(String[] args) throws Exception {
        HttpURLConnection connection = (HttpURLConnection) new URL("http://127.0.0.1:8080/health").openConnection();
        connection.setConnectTimeout(2000);
        connection.setReadTimeout(2000);
        connection.setRequestMethod("GET");
        try {
            if (connection.getResponseCode() != HttpURLConnection.HTTP_OK) {
                System.exit(1);
            }
        } finally {
            connection.disconnect();
        }
    }
}
