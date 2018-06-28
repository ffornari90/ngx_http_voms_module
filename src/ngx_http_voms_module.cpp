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
#include <memory>
#include <numeric>
#include <string>
#include <boost/algorithm/string/join.hpp>
#include <boost/optional.hpp>

using BioPtr = std::unique_ptr<BIO, decltype(&BIO_free)>;
using X509Ptr = std::unique_ptr<X509, decltype(&X509_free)>;
using VomsAc = voms;
using MaybeVomsAc = boost::optional<VomsAc>;

enum class EeDn { SUBJECT, ISSUER };

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

  if (!vomsdata_ptr) {
    vomsdata_ptr.reset(new vomsdata);
  }
  auto ok =
      vomsdata_ptr->Retrieve(client_cert.get(), client_chain, RECURSE_CHAIN);
  if (!ok) {
    auto msg = vomsdata_ptr->ErrorMessage().c_str();
    ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "%s", msg);
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
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __func__);

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
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __func__);

  MaybeVomsAc* acp = get_voms_ac_from_cache(r);

  if (!acp) {
    acp = new MaybeVomsAc(retrieve_voms_ac_from_proxy(r));
    cache_voms_ac(r, acp);
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
    // find first non-proxy
    for (int i = 0; i != sk_X509_num(chain); ++i) {
      auto cert = sk_X509_value(chain, i);
      if (cert && !is_proxy(cert)) {
        ee_cert = cert;
        break;
      }
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

static ngx_int_t get_ssl_client_ee_cert_raw(ngx_http_request_t* r, ngx_str_t* s)
{
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __func__);
  s->len = 0;

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
        NGX_LOG_ERR, r->connection->log, 0, "cannot write EEC to OpenSSL bio");
    return NGX_ERROR;
  }

  size_t len = BIO_pending(bio.get());

  s->len = len;
  s->data = static_cast<u_char*>(ngx_pnalloc(r->pool, len));

  if (s->data == nullptr) {
    return NGX_ERROR;
  }

  BIO_read(bio.get(), s->data, len);

  return NGX_OK;
}

static ngx_int_t get_ssl_client_ee_cert(ngx_http_request_t* r,
                                        ngx_http_variable_value_t* v,
                                        uintptr_t data)
{
  ngx_log_error(NGX_LOG_DEBUG, r->connection->log, 0, "%s", __func__);

  v->not_found = 1;
  v->valid = 0;

  ngx_str_t cert;

  if (get_ssl_client_ee_cert_raw(r, &cert) != NGX_OK) {
    return NGX_ERROR;
  }

  if (cert.len == 0) {
    v->len = 0;
    return NGX_OK;
  }

  size_t len = cert.len - 1;

  for (int i = 0; i < cert.len - 1; i++) {
    if (cert.data[i] == '\n') {
      len++;
    }
  }

  auto buffer = static_cast<u_char*>(ngx_pnalloc(r->pool, len));

  if (!buffer) {
    return NGX_OK;
  }

  u_char* p = buffer;

  for (int i = 0; i < cert.len - 1; i++) {
    *p++ = cert.data[i];
    if (cert.data[i] == '\n') {
      *p++ = '\t';
    }
  }

  v->data = buffer;
  v->len = len;
  v->valid = 1;
  v->not_found = 0;
  v->no_cacheable = 0;
  return NGX_OK;
}
