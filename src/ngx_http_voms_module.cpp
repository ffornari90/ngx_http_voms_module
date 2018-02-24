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

static std::unique_ptr<vomsdata> vomsdata_ptr;

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

  if (!vomsdata_ptr) {
    vomsdata_ptr.reset(new vomsdata);
  }
  auto ok =
      vomsdata_ptr->Retrieve(client_cert.get(), client_chain, RECURSE_CHAIN);
  if (!ok) {
    // vd.error is not interpreted correctly by the logger, which probably uses
    // errno
    ngx_log_error(NGX_LOG_ERR,
                  r->connection->log,
                  vomsdata_ptr->error,
                  "%s",
                  vomsdata_ptr->ErrorMessage().c_str());
    return boost::none;
  }

  if (vomsdata_ptr->data.empty()) {
    ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "no ACs in proxy");
    return boost::none;
  }

  return vomsdata_ptr->data.front();
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

  auto fqans = boost::algorithm::join(ac->fqan, ",");

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
