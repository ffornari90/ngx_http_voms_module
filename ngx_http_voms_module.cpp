extern "C" {
#include <ngx_config.h>
#include <ngx_core.h>
#include <ngx_http.h>
}
#include <voms/voms_api.h>
#include <cassert>
#include <chrono>
#include <iostream>
#include <memory>
#include <numeric>
#include <string>
#include <boost/algorithm/string/join.hpp>
#include <boost/optional.hpp>

using BioPtr = std::unique_ptr<BIO, decltype(&BIO_free)>;
using X509Ptr = std::unique_ptr<X509, decltype(&X509_free)>;
using VomsAc = voms;
using MaybeVomsAc = boost::optional<VomsAc>;

static ngx_int_t add_variables(ngx_conf_t* cf);

static ngx_http_module_t ctx = {
    add_variables,  // preconfiguration
    NULL,           // postconfiguration
    NULL,           // create main configuration
    NULL,           // init main configuration
    NULL,           // create server configuration
    NULL,           // merge server configuration
    NULL,           // create location configuration
    NULL            // merge location configuration
};

ngx_module_t ngx_http_voms_module = {
    NGX_MODULE_V1,
    &ctx,                  // module context
    NULL,                  // module directives
    NGX_HTTP_MODULE,       // module type
    NULL,                  // init master
    NULL,                  // init module
    NULL,                  // init process
    NULL,                  // init thread
    NULL,                  // exit thread
    NULL,                  // exit process
    NULL,                  // exit master
    NGX_MODULE_V1_PADDING  //
};

static ngx_int_t get_voms_fqans(  //
    ngx_http_request_t* r,
    ngx_http_variable_value_t* v,
    uintptr_t data);
static ngx_int_t get_voms_user(  //
    ngx_http_request_t* r,
    ngx_http_variable_value_t* v,
    uintptr_t data);

static ngx_http_variable_t variables[] = {
    {
        ngx_string("voms_fqans"),
        NULL,
        get_voms_fqans,
        0,
        NGX_HTTP_VAR_NOCACHEABLE,
        0  //
    },
    {
        ngx_string("voms_user"),
        NULL,
        get_voms_user,
        0,
        NGX_HTTP_VAR_NOCACHEABLE,
        0  //
    },
    ngx_http_null_variable  //
};

static ngx_int_t add_variables(ngx_conf_t* cf)
{
  for (ngx_http_variable_t* v = variables; v->name.len; ++v) {
    ngx_http_variable_t* var = ngx_http_add_variable(cf, &v->name, v->flags);
    if (var == NULL) {
      return NGX_ERROR;
    }

    var->get_handler = v->get_handler;
    var->data = v->data;
  }

  return NGX_OK;
}

template <class S>
static std::string to_string(S const* s)
{
  return std::string(reinterpret_cast<char const*>(s->data),
                     reinterpret_cast<char const*>(s->data) + s->len);
}

boost::optional<std::string> to_pem(X509& x509)
{
  BioPtr bio{BIO_new(BIO_s_mem()), BIO_free};
  if (PEM_write_bio_X509(bio.get(), &x509) == 0) {
    return boost::none;
  } else {
    char* data = nullptr;
    auto len = BIO_get_mem_data(bio.get(), &data);
    if (len > 0) {
      return std::string(data, data + len);
    } else {
      return boost::none;
    }
  }
}

// return the first AC, if present
static MaybeVomsAc retrieve_voms_ac_from_proxy(ngx_http_request_t* r)
{
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __FUNCTION__);

  if (!r->http_connection->ssl) {
    return boost::none;
  }

  auto client_cert = X509Ptr{
      SSL_get_peer_certificate(r->connection->ssl->connection), X509_free};
  if (!client_cert) {
    ngx_log_error(NGX_LOG_ERR,
                  r->connection->log,
                  0,
                  "SSL_get_peer_certificate() failed");
    return boost::none;
  }

  auto client_chain = SSL_get_peer_cert_chain(r->connection->ssl->connection);
  if (!client_chain) {
    ngx_log_error(
        NGX_LOG_ERR, r->connection->log, 0, "SSL_get_peer_cert_chain() failed");
    return boost::none;
  }

  vomsdata vd;
  auto ok = vd.Retrieve(client_cert.get(), client_chain, RECURSE_CHAIN);
  if (!ok) {
    // vd.error is not interpreted correctly by the logger, which probably uses
    // errno
    ngx_log_error(NGX_LOG_ERR,
                  r->connection->log,
                  vd.error,
                  "%s",
                  vd.ErrorMessage().c_str());
    return boost::none;
  }

  if (vd.data.empty()) {
    ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "no ACs in proxy");
    return boost::none;
  }

  return vd.data.front();
}

static void clean_voms_ac(void* data)
{
  auto r = static_cast<ngx_http_request_t*>(data);
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __FUNCTION__);

  auto p = static_cast<MaybeVomsAc*>(
      ngx_http_get_module_ctx(r, ngx_http_voms_module));
  delete p;
}

static void cache_voms_ac(ngx_http_request_t* r, MaybeVomsAc* ac)
{
  ngx_http_set_ctx(r, ac, ngx_http_voms_module);
  auto cln = ngx_http_cleanup_add(r, 0);
  if (cln) {
    cln->handler = clean_voms_ac;
    cln->data = r;
  } else {
    ngx_log_error(
        NGX_LOG_ERR, r->connection->log, 0, "ngx_http_cleanup_add() failed");
  }
}

static MaybeVomsAc* get_voms_ac_from_cache(ngx_http_request_t* r)
{
  return static_cast<MaybeVomsAc*>(
      ngx_http_get_module_ctx(r, ngx_http_voms_module));
}

static MaybeVomsAc const& get_voms_ac(ngx_http_request_t* r)
{
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __FUNCTION__);

  MaybeVomsAc* acp = get_voms_ac_from_cache(r);

  if (!acp) {
    acp = new MaybeVomsAc(retrieve_voms_ac_from_proxy(r));
    cache_voms_ac(r, acp);
  }

  return *acp;
}

static ngx_int_t get_voms_fqans(ngx_http_request_t* r,
                                ngx_http_variable_value_t* v,
                                uintptr_t)
{
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __FUNCTION__);

  v->not_found = 1;
  v->valid = 0;

  auto& ac = get_voms_ac(r);

  if (!ac) {
    ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "get_voms_ac() failed");
    return NGX_OK;
  }

  auto fqans = boost::algorithm::join(ac->fqans, ",");

  auto data = static_cast<u_char*>(ngx_pnalloc(r->pool, fqans.size()));
  if (!data) {
    ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "ngx_pnalloc() failed");
    return NGX_OK;
  }
  ngx_memcpy(data, fqans.c_str(), fqans.size());

  v->data = data;
  v->len = fqans.size();
  v->valid = 1;
  v->not_found = 0;
  v->no_cacheable = 0;
  return NGX_OK;
}

static ngx_int_t get_voms_user(ngx_http_request_t* r,
                               ngx_http_variable_value_t* v,
                               uintptr_t)
{
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __FUNCTION__);

  v->not_found = 1;
  v->valid = 0;

  auto& ac = get_voms_ac(r);

  if (!ac) {
    ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "get_voms_ac() failed");
    return NGX_OK;
  }

  auto const& user = ac->user;

  auto data = static_cast<u_char*>(ngx_pnalloc(r->pool, user.size()));
  if (!data) {
    ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "ngx_pnalloc() failed");
    return NGX_OK;
  }
  ngx_memcpy(data, user.c_str(), user.size());

  v->data = data;
  v->len = user.size();
  v->valid = 1;
  v->not_found = 0;
  v->no_cacheable = 0;
  return NGX_OK;
}

ngx_int_t get_voms(ngx_http_request_t* r,
                   ngx_http_variable_value_t* v,
                   uintptr_t data)
{
  // to show that get_voms gets called only once, even if the variable is used
  // twice in the configuration file
  static int count = 0;
  assert(count == 0);
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "get_voms");

  {
    auto t0 = std::chrono::high_resolution_clock::now();

    static ngx_str_t var = ngx_string("ssl_client_raw_cert");
    u_char unused[sizeof("ssl_client_raw_cert")];

    auto hash = ngx_hash_strlow(unused, var.data, var.len);

    ngx_http_variable_value_t* raw_cert = ngx_http_get_variable(r, &var, hash);

    // da rivedere gli errori ritornati (sempre che siano errori)

    if (!raw_cert || raw_cert->not_found || !raw_cert->valid) {
      ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "invalid raw_cert");
      return NGX_OK;
    }

    BioPtr bio{BIO_new(BIO_s_mem()), BIO_free};
    if (BIO_write(bio.get(), raw_cert->data, raw_cert->len) != raw_cert->len) {
      ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "BIO_write() failed");
      return NGX_OK;
    }

    X509Ptr x509{PEM_read_bio_X509(bio.get(), NULL, NULL, NULL), X509_free};
    if (!x509) {
      ngx_log_error(
          NGX_LOG_DEBUG, r->connection->log, 0, "PEM_read_bio_X509() failed");
      return NGX_OK;
    }

    auto t1 = std::chrono::high_resolution_clock::now();

    ngx_log_error(NGX_LOG_DEBUG,
                  r->connection->log,
                  0,
                  "time 1: %f us",
                  std::chrono::duration<double, std::micro>(t1 - t0).count());

    ngx_log_error(NGX_LOG_DEBUG,
                  r->connection->log,
                  0,
                  "raw_cert: %s",
                  to_string(raw_cert).c_str());
  }

  v->valid = 1;
  v->no_cacheable = 1;
  v->not_found = 0;

  v->data = (u_char*)"VOMS";
  v->len = 4;

  return NGX_OK;
}
