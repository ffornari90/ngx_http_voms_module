// Copyright 2018 Istituto Nazionale di Fisica Nucleare
//
// Licensed under the EUPL, Version 1.2 or - as soon they will be approved by
// the European Commission - subsequent versions of the EUPL (the "Licence").
// You may not use this work except in compliance with the Licence. You may
// obtain a copy of the Licence at:
//
// https://joinup.ec.europa.eu/software/page/eupl
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the Licence is distributed on an "AS IS" basis, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// Licence for the specific language governing permissions and limitations under
// the Licence.

extern "C" {
#include <ngx_config.h>
#include <ngx_core.h>
#include <ngx_http.h>
}
#include <voms/voms_api.h>
#include <cassert>
#include <chrono>
#include <iostream>
#include <map>
#include <memory>
#include <numeric>
#include <string>
#include <boost/algorithm/string/join.hpp>
#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>

using BioPtr = std::unique_ptr<BIO, decltype(&BIO_free)>;
using X509Ptr = std::unique_ptr<X509, decltype(&X509_free)>;
using VomsAc = voms;
using MaybeVomsAc = boost::optional<VomsAc>;

enum class EeDn { SUBJECT, ISSUER };

static ngx_int_t add_variables(ngx_conf_t* cf);
static ngx_int_t ngx_ssl_allow_proxy_certs(ngx_ssl_t* ssl);
static char* ngx_http_voms_merge_srv_conf(ngx_conf_t* cf, void*, void*);

static ngx_http_module_t ctx = {
    add_variables,                 // preconfiguration
    NULL,                          // postconfiguration
    NULL,                          // create main configuration
    NULL,                          // init main configuration
    NULL,                          // create server configuration
    ngx_http_voms_merge_srv_conf,  // merge server configuration
    NULL,                          // create location configuration
    NULL                           // merge location configuration
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

static ngx_int_t generic_getter(  //
    ngx_http_request_t* r,
    ngx_http_variable_value_t* v,
    uintptr_t data);

static ngx_int_t get_ssl_client_ee_dn(  //
    ngx_http_request_t* r,
    ngx_http_variable_value_t* v,
    uintptr_t data);

static ngx_int_t get_ssl_client_ee_cert(  //
    ngx_http_request_t* r,
    ngx_http_variable_value_t* v,
    uintptr_t data);

using getter_t = std::string(VomsAc const& voms);
static getter_t get_voms_user;
static getter_t get_voms_user_ca;
static getter_t get_voms_fqans;
static getter_t get_voms_server;
static getter_t get_voms_server_ca;
static getter_t get_voms_vo;
static getter_t get_voms_server_uri;
static getter_t get_voms_not_before;
static getter_t get_voms_not_after;
static getter_t get_voms_generic_attributes;
static getter_t get_voms_serial;

static ngx_http_variable_t variables[] = {
    {
        ngx_string("voms_user"),
        NULL,
        generic_getter,
        reinterpret_cast<uintptr_t>(&get_voms_user),
        NGX_HTTP_VAR_NOCACHEABLE,
        0  //
    },
    {
        ngx_string("voms_user_ca"),
        NULL,
        generic_getter,
        reinterpret_cast<uintptr_t>(&get_voms_user_ca),
        NGX_HTTP_VAR_NOCACHEABLE,
        0  //
    },
    {
        ngx_string("voms_fqans"),
        NULL,
        generic_getter,
        reinterpret_cast<uintptr_t>(&get_voms_fqans),
        NGX_HTTP_VAR_NOCACHEABLE,
        0  //
    },
    {
        ngx_string("voms_server"),
        NULL,
        generic_getter,
        reinterpret_cast<uintptr_t>(&get_voms_server),
        NGX_HTTP_VAR_NOCACHEABLE,
        0  //
    },
    {
        ngx_string("voms_server_ca"),
        NULL,
        generic_getter,
        reinterpret_cast<uintptr_t>(&get_voms_server_ca),
        NGX_HTTP_VAR_NOCACHEABLE,
        0  //
    },
    {
        ngx_string("voms_vo"),
        NULL,
        generic_getter,
        reinterpret_cast<uintptr_t>(&get_voms_vo),
        NGX_HTTP_VAR_NOCACHEABLE,
        0  //
    },
    {
        ngx_string("voms_server_uri"),
        NULL,
        generic_getter,
        reinterpret_cast<uintptr_t>(&get_voms_server_uri),
        NGX_HTTP_VAR_NOCACHEABLE,
        0  //
    },
    {
        ngx_string("voms_not_before"),
        NULL,
        generic_getter,
        reinterpret_cast<uintptr_t>(&get_voms_not_before),
        NGX_HTTP_VAR_NOCACHEABLE,
        0  //
    },
    {
        ngx_string("voms_not_after"),
        NULL,
        generic_getter,
        reinterpret_cast<uintptr_t>(&get_voms_not_after),
        NGX_HTTP_VAR_NOCACHEABLE,
        0  //
    },
    {
        ngx_string("voms_generic_attributes"),
        NULL,
        generic_getter,
        reinterpret_cast<uintptr_t>(&get_voms_generic_attributes),
        NGX_HTTP_VAR_NOCACHEABLE,
        0  //
    },
    {
        ngx_string("voms_serial"),
        NULL,
        generic_getter,
        reinterpret_cast<uintptr_t>(&get_voms_serial),
        NGX_HTTP_VAR_NOCACHEABLE,
        0  //
    },
    {
        ngx_string("ssl_client_ee_s_dn"),
        NULL,
        get_ssl_client_ee_dn,
        static_cast<uintptr_t>(EeDn::SUBJECT),
        NGX_HTTP_VAR_NOCACHEABLE,
        0  //
    },
    {
        ngx_string("ssl_client_ee_i_dn"),
        NULL,
        get_ssl_client_ee_dn,
        static_cast<uintptr_t>(EeDn::ISSUER),
        NGX_HTTP_VAR_NOCACHEABLE,
        0  //
    },
    {
        ngx_string("ssl_client_ee_cert"),
        NULL,
        get_ssl_client_ee_cert,
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

static ngx_int_t ngx_ssl_allow_proxy_certs(ngx_ssl_t* ssl)
{
  X509_STORE* store = SSL_CTX_get_cert_store(ssl->ctx);
  if (store == NULL) {
    ngx_ssl_error(NGX_LOG_EMERG,
                  ssl->log,
                  0,
                  const_cast<char*>("SSL_CTX_get_cert_store() failed"));
    return NGX_ERROR;
  }

  X509_STORE_set_flags(store, X509_V_FLAG_ALLOW_PROXY_CERTS);

  return NGX_OK;
}

static char* ngx_http_voms_merge_srv_conf(ngx_conf_t* cf, void*, void*)
{
  auto conf = static_cast<ngx_http_ssl_srv_conf_t*>(
      ngx_http_conf_get_module_srv_conf(cf, ngx_http_ssl_module));

  if (conf->ssl.ctx != nullptr) {
    if (ngx_ssl_allow_proxy_certs(&conf->ssl) != NGX_OK) {
      return static_cast<char*>(NGX_CONF_ERROR);
    }
  }

  return NGX_CONF_OK;
}

// return the first AC, if present
static MaybeVomsAc retrieve_voms_ac_from_proxy(ngx_http_request_t* r)
{
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __func__);

  if (!r->http_connection->ssl) {
    ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "SSL not enabled");
    return boost::none;
  }

  auto client_cert = X509Ptr{
      SSL_get_peer_certificate(r->connection->ssl->connection), X509_free};
  if (!client_cert) {
    ngx_log_error(NGX_LOG_ERR,
                  r->connection->log,
                  0,
                  "no SSL peer certificate available");
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
    auto msg = vd.ErrorMessage();
    ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "%s", msg.c_str());
    return boost::none;
  }

  if (vd.data.empty()) {
    ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "no ACs in proxy");
    return boost::none;
  }

  return vd.data.front();
}

// note that an entry in the cache is always created if within a connection a
// request is made to one of the voms_* variables. If the presented
// credential is a normal certificate or a proxy without attribute certificates,
// the unique_ptr points to a MaybeVomsAc that is empty (in the sense of an
// std::optional)
static std::map<ngx_connection_t*, std::unique_ptr<MaybeVomsAc>> ac_cache;

static void clean_voms_ac(void* data)
{
  auto c = static_cast<ngx_connection_t*>(data);
  ngx_log_error(NGX_LOG_DEBUG, c->log, 0, "%s", __func__);
  auto n = ac_cache.erase(c);
  // we erase from the cache exactly once per connection
  assert(n == 1);
}

static void cache_voms_ac(ngx_http_request_t* r,
                          std::unique_ptr<MaybeVomsAc> acp)
{
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __func__);
  auto c = r->connection;
  auto cln = ngx_pool_cleanup_add(c->pool, 0);
  if (cln) {
    auto r = ac_cache.insert({c, std::move(acp)});
    // we insert into the cache exactly once per connection
    assert(r.second);
    cln->handler = clean_voms_ac;
    cln->data = c;
  } else {
    ngx_log_error(
        NGX_LOG_ERR, r->connection->log, 0, "ngx_pool_cleanup_add() failed");
  }
}

static MaybeVomsAc* get_voms_ac_from_cache(ngx_http_request_t* r)
{
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __func__);
  auto it = ac_cache.find(r->connection);
  return it != ac_cache.end() ? it->second.get() : nullptr;
}

static MaybeVomsAc const& get_voms_ac(ngx_http_request_t* r)
{
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __func__);

  MaybeVomsAc* acp = get_voms_ac_from_cache(r);

  if (!acp) {
    auto p = std::make_unique<MaybeVomsAc>(retrieve_voms_ac_from_proxy(r));
    acp = p.get();
    cache_voms_ac(r, std::move(p));
  }

  return *acp;
}

static ngx_int_t generic_getter(ngx_http_request_t* r,
                                ngx_http_variable_value_t* v,
                                uintptr_t data)
{
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __func__);

  v->not_found = 1;
  v->valid = 0;

  auto& ac = get_voms_ac(r);

  if (!ac) {
    ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "get_voms_ac() failed");
    return NGX_OK;
  }

  using getter_p = std::string (*)(VomsAc const& voms);
  auto getter = reinterpret_cast<getter_p>(data);
  std::string const value = getter(*ac);

  auto buffer = static_cast<u_char*>(ngx_pnalloc(r->pool, value.size()));
  if (!buffer) {
    return NGX_OK;
  }
  ngx_memcpy(buffer, value.c_str(), value.size());

  v->data = buffer;
  v->len = value.size();
  v->valid = 1;
  v->not_found = 0;
  v->no_cacheable = 0;
  return NGX_OK;
}

std::string get_voms_user(VomsAc const& ac)
{
  return ac.user;
}

std::string get_voms_user_ca(VomsAc const& ac)
{
  return ac.userca;
}

std::string get_voms_fqans(VomsAc const& ac)
{
  return boost::algorithm::join(ac.fqan, ",");
}

std::string get_voms_server(VomsAc const& ac)
{
  return ac.server;
}

std::string get_voms_server_ca(VomsAc const& ac)
{
  return ac.serverca;
}

std::string get_voms_vo(VomsAc const& ac)
{
  return ac.voname;
}

std::string get_voms_server_uri(VomsAc const& ac)
{
  return ac.uri;
}

std::string get_voms_not_before(VomsAc const& ac)
{
  return ac.date1;
}

std::string get_voms_not_after(VomsAc const& ac)
{
  return ac.date2;
}

static std::string escape_uri(std::string const& src)
{
  std::string result = src;

  // the following just counts the number of characters that need escaping
  auto const n_escape =
      ngx_escape_uri(nullptr,  // <--
                     reinterpret_cast<u_char*>(const_cast<char*>(src.data())),
                     src.size(),
                     NGX_ESCAPE_URI_COMPONENT);

  if (n_escape > 0) {
    result.resize(src.size() + 2 * n_escape);
    ngx_escape_uri(reinterpret_cast<u_char*>(const_cast<char*>(result.data())),
                   reinterpret_cast<u_char*>(const_cast<char*>(src.data())),
                   src.size(),
                   NGX_ESCAPE_URI_COMPONENT);
  }

  return result;
}

static std::string encode(attribute const& a)
{
  return "n=" + a.name + " v=" + escape_uri(a.value) + " q=" + a.qualifier;
}

std::string get_voms_generic_attributes(VomsAc const& ac)
{
  std::string result;

  // the GetAttributes method is not declared const
  auto const attributes = const_cast<VomsAc&>(ac).GetAttributes();
  if (!attributes.empty()) {
    auto& gas = attributes.front().attributes;
    bool first = true;
    for (auto& a : gas) {
      if (first) {
        first = false;
      } else {
        result += ',';
      }
      result += encode(a);
    }
  }

  return result;
}

std::string get_voms_serial(VomsAc const& ac)
{
  return ac.serial;
}

static std::string to_rfc2253(X509_NAME* name)
{
  std::string result;

  BioPtr bio(BIO_new(BIO_s_mem()), &BIO_free);
  if (!bio) {
    return result;
  }

  if (X509_NAME_print_ex(bio.get(), name, 0, XN_FLAG_RFC2253) < 0) {
    return result;
  }

  auto len = BIO_pending(bio.get());
  result.resize(len);

  BIO_read(bio.get(), &result[0], result.size());

  return result;
}

#if OPENSSL_VERSION_NUMBER < 0x10100000L
static uint32_t X509_get_extension_flags(X509* x)
{
  return x->ex_flags;
}
#endif

static bool is_ca(X509* cert)
{
  return X509_check_ca(cert) != 0;
}

static bool is_proxy(X509* cert)
{
  return X509_get_extension_flags(cert) & EXFLAG_PROXY;
}

static X509* get_ee_cert(ngx_http_request_t* r)
{
  auto chain = SSL_get_peer_cert_chain(r->connection->ssl->connection);
  if (!chain) {
    ngx_log_error(
        NGX_LOG_ERR, r->connection->log, 0, "SSL_get_peer_cert_chain() failed");
    return nullptr;
  }

  X509* ee_cert = nullptr;

  if (sk_X509_num(chain) == 0) {
    ee_cert = SSL_get_peer_certificate(r->connection->ssl->connection);
  } else {
    // find first non-proxy and non-ca cert
    for (int i = 0; i != sk_X509_num(chain); ++i) {
      auto cert = sk_X509_value(chain, i);
      if (is_ca(cert)) {
        break;
      }
      if (cert && !is_proxy(cert)) {
        ee_cert = cert;
        break;
      }
    }

    if (!ee_cert) {
      ee_cert = SSL_get_peer_certificate(r->connection->ssl->connection);
    }
  }

  return ee_cert;
}

static ngx_int_t get_ssl_client_ee_dn(ngx_http_request_t* r,
                                      ngx_http_variable_value_t* v,
                                      uintptr_t data)
{
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __func__);

  v->not_found = 1;
  v->valid = 0;

  auto ee_cert = get_ee_cert(r);

  if (!ee_cert) {
    ngx_log_error(NGX_LOG_DEBUG,
                  r->connection->log,
                  0,
                  "cannot identify end-entity certificate");
    return NGX_OK;
  }

  X509_NAME* dn;

  switch (static_cast<EeDn>(data)) {
    case EeDn::SUBJECT:
      dn = X509_get_subject_name(ee_cert);
      break;
    case EeDn::ISSUER:
      dn = X509_get_issuer_name(ee_cert);
      break;
    default:
      dn = nullptr;
  }

  if (!dn) {
    ngx_log_error(
        NGX_LOG_DEBUG, r->connection->log, 0, "cannot get DN from certificate");
    return NGX_OK;
  }
  std::string value = to_rfc2253(dn);

  auto buffer = static_cast<u_char*>(ngx_pnalloc(r->pool, value.size()));
  if (!buffer) {
    return NGX_OK;
  }
  ngx_memcpy(buffer, value.c_str(), value.size());

  v->data = buffer;
  v->len = value.size();
  v->valid = 1;
  v->not_found = 0;
  v->no_cacheable = 0;
  return NGX_OK;
}

static ngx_int_t get_ssl_client_ee_cert_raw(ngx_http_request_t* r,
                                            ngx_str_t* result)
{
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __func__);

  *result = {};

  auto ee_cert = get_ee_cert(r);

  if (!ee_cert) {
    ngx_log_error(NGX_LOG_DEBUG,
                  r->connection->log,
                  0,
                  "cannot identify end-entity certificate");
    return NGX_OK;
  }

  BioPtr bio(BIO_new(BIO_s_mem()), &BIO_free);
  if (!bio) {
    ngx_log_error(
        NGX_LOG_ERR, r->connection->log, 0, "cannot create OpenSSL BIO");
    return NGX_ERROR;
  }

  if (PEM_write_bio_X509(bio.get(), ee_cert) == 0) {
    ngx_log_error(
        NGX_LOG_ERR, r->connection->log, 0, "cannot write EEC to OpenSSL BIO");
    return NGX_ERROR;
  }

  result->len = BIO_pending(bio.get());
  result->data = static_cast<u_char*>(ngx_pnalloc(r->pool, result->len));

  if (result->data == nullptr) {
    return NGX_ERROR;
  }

  BIO_read(bio.get(), result->data, result->len);

  return NGX_OK;
}

static ngx_int_t get_ssl_client_ee_cert(ngx_http_request_t* r,
                                        ngx_http_variable_value_t* v,
                                        uintptr_t data)
{
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __func__);

  v->not_found = 1;
  v->valid = 0;

  ngx_str_t cert{};

  if (get_ssl_client_ee_cert_raw(r, &cert) != NGX_OK) {
    return NGX_ERROR;
  }

  if (cert.len == 0) {
    v->len = 0;
    return NGX_OK;
  }

  // the first line is not prepended with a tab
  auto const n_tabs = std::count(cert.data, cert.data + cert.len, '\n') - 1;
  // cert is null-terminated
  auto const len = cert.len - 1 + n_tabs;

  auto const buffer = static_cast<u_char*>(ngx_pnalloc(r->pool, len));

  if (!buffer) {
    return NGX_OK;
  }

  // the last newline is not to be followed by a tab
  boost::algorithm::replace_all_copy(
      buffer, boost::make_iterator_range_n(cert.data, len - 1), "\n", "\n\t");

  v->data = buffer;
  v->len = len;
  v->valid = 1;
  v->not_found = 0;
  v->no_cacheable = 0;
  return NGX_OK;
}
