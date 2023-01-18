use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 2: EEC
--- main_config
    env X509_VOMS_DIR=t/vomsdir;
    env X509_CERT_DIR=t/trust-anchors;
    load_module /etc/nginx/modules/ngx_http_voms_module.so;
--- http_config
    server {
        error_log logs/error.log debug;
        listen 8443 ssl;
        ssl_certificate ../../certs/star.test.example.cert.pem;
        ssl_certificate_key ../../certs/star.test.example.key.pem;
        ssl_client_certificate ../../trust-anchors/igi-test-ca.pem;
        ssl_verify_depth 10;
        ssl_verify_client on;
	location = / {
            default_type text/plain;
            return 200 "$ssl_client_ee_cert\n";
        }
    }
--- config
    location = / {
        error_log logs/error-proxy.log debug;
        proxy_pass https://localhost:8443/;
        proxy_ssl_certificate ../../certs/test0.cert.pem;
        proxy_ssl_certificate_key ../../certs/9.key.pem;
    }
--- request
GET / 
--- response_body
-----BEGIN CERTIFICATE-----
	MIIDnjCCAoagAwIBAgIBCDANBgkqhkiG9w0BAQUFADAtMQswCQYDVQQGEwJJVDEM
	MAoGA1UECgwDSUdJMRAwDgYDVQQDDAdUZXN0IENBMB4XDTIyMTAwMTEzMTYzMloX
	DTMyMDkyODEzMTYzMlowKzELMAkGA1UEBhMCSVQxDDAKBgNVBAoMA0lHSTEOMAwG
	A1UEAwwFdGVzdDAwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCoyIIN
	H7YaqKMIW4kI41E0gDqtaQKYKdCv1cDL9/ibg0QLO/hyak9u9zQnp7XlK6e9NwnM
	T3efn3o5xWyA4nY8UWvXQRxQjuQO1hxManxFxzVHYYkd5p4JDy3lrDSPgw8yojPZ
	iAwVcDWZfVzXEC/EEAtbheSZcydQaEWSCLmY9rrriyvxrIlYaiAzXFhV0hRsxPy9
	Fk85nq1JVzeAN7jVt3JVrDgHd17IQIySXz3JU7UYChGcW3CO4LNe4p39cbjW6wbi
	Uqo+7caSJsOxwoS2RcHAahgd+BGegMkr48krmojuDcYrrkAL4AK0Uh5xXdWul1kG
	0SFf0WyN23CjuFEXAgMBAAGjgcowgccwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU
	aognKvxLiK8OSA1F/9x+7qCDtuUwDgYDVR0PAQH/BAQDAgXgMD4GA1UdJQQ3MDUG
	CCsGAQUFBwMBBggrBgEFBQcDAgYKKwYBBAGCNwoDAwYJYIZIAYb4QgQBBggrBgEF
	BQcDBDAfBgNVHSMEGDAWgBRQm290AeMaA1er2dV9FWRMJfP49DAnBgNVHREEIDAe
	gRxhbmRyZWEuY2VjY2FudGlAY25hZi5pbmZuLml0MA0GCSqGSIb3DQEBBQUAA4IB
	AQBHBk5Pcr3EXJZedPeEQuXCdPMDAJpAcZTCTINfGRoQXDYQk6ce8bH8jHPmao6d
	qV/f/14y2Jmkz+aiFQhSSyDLk4ywTgGHT+kpWEsYGbN4AdcMlH1L9uaG7YbuAZzH
	6bkd8HLsTiwslXYHjyldbQL9ZU6DrGAdt/IuAfFrQjWWuJ21SfBlnp4OkWQK5wTk
	sTvfeZX6VwinpXzF6xIrtAfJ7OYRDuN7UIrwBl9G0hoQPuXFJeVRAzYRwDVbejSo
	/8OWCj17EXDO+tG6Md+JYIsqJ4wrytd4YeuYDVDzbVV8DHfMrk2+PeJ0nSOSyYV+
	doaFzJ6837vw8+5gxDTHT/un
	-----END CERTIFICATE-----
--- error_code: 200
