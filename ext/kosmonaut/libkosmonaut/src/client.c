#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>

#include "utils.h"
#include "kosmonaut.h"

#define DEFAULT_REQ_TIMEOUT 2000
#define DEFAULT_RES_TIMEOUT 2000

static int
s_kosmonaut_client_get_error_code (zmsg_t* msg)
{
    int errc;
    char* frame;

    frame = zmsg_popstr(msg);
    sscanf(frame, "%d", &errc);
    free(frame);
    return errc;
}

static int
s_kosmonaut_client_parse_response (zmsg_t* msg)
{
    int rc = -1;
    zframe_t* cmd;

    cmd = zmsg_pop(msg);

    if (zframe_streq(cmd, CMD_ERROR)) {
        if (zmsg_size(msg) >= 1)
            rc = s_kosmonaut_client_get_error_code(msg);
    } else if (zframe_streq(cmd, CMD_OK)) {
        rc = 0;
    } else if (zframe_streq(cmd, CMD_ACCESS_TOKEN)) {
        rc = 0;
    }

    zframe_destroy(&cmd);
    return rc;
}

static zmsg_t*
s_kosmonaut_client_request (kosmonaut_client_t* self,
                            char* command,
                            zmsg_t** request_p)
{
    zmsg_t* response;
    zmsg_t* request;
    zmq_pollitem_t items[1];
    int rc;
    
    assert(self);
    assert(command);
    pthread_mutex_lock(&self->mtx);

    request = request_p && *request_p ? *request_p : zmsg_new();
    items[0].socket = self->socket;
    items[0].events = ZMQ_POLLOUT|ZMQ_POLLIN;
    
    rc = zmq_poll(items, 1, self->req_timeout * ZMQ_POLL_MSEC);
    if (rc != -1 && items[0].revents & ZMQ_POLLOUT) {
        zmsg_pushstr(request, command);
        zmsg_send(&request, self->socket);

        rc = zmq_poll(items, 1, self->res_timeout * ZMQ_POLL_MSEC);
        if (rc != -1 && items[0].revents & ZMQ_POLLIN) {
            response = zmsg_recv(self->socket);
        }
    }
    
    pthread_mutex_unlock(&self->mtx);
    return response;
}

kosmonaut_client_t*
kosmonaut_client_new (const char* vhost,
                      const char* secret)
{
    kosmonaut_client_t* self;
    
    assert(vhost);
    assert(secret);
    
    self = (kosmonaut_client_t*)malloc(sizeof(kosmonaut_client_t));
    self->identity = generate_identity("req", vhost, secret);
    self->req_timeout = DEFAULT_REQ_TIMEOUT;
    self->res_timeout = DEFAULT_RES_TIMEOUT;
    self->ctx = zctx_new();
    self->socket = zsocket_new(self->ctx, ZMQ_REQ);
    zsockopt_set_identity(self->socket, self->identity);    
    pthread_mutex_init(&self->mtx, NULL);

    return self;
}

int
kosmonaut_client_connect (kosmonaut_client_t* self,
                          const char* addr)
{
    assert(self);
    assert(addr);
    return zsocket_connect(self->socket, addr);
}

void
kosmonaut_client_disconnect (kosmonaut_client_t* self)
{
    assert(self);
    zsocket_destroy(self->ctx, self->socket);
}

int
kosmonaut_client_broadcast (kosmonaut_client_t* self,
                            const char* channel,
                            const char* event,
                            const char* data)
{ 
    int rc = -1;
    zmsg_t* request;
    zmsg_t* response;
    
    assert(self);
    assert(channel);
    assert(event);
    assert(data);
    
    request = zmsg_new();
    zmsg_addstr(request, channel);
    zmsg_addstr(request, event);
    zmsg_addstr(request, data);

    response = s_kosmonaut_client_request(self, CMD_BROADCAST, &request);
    
    if (response) {
        if (zmsg_size(response) >= 1)
            rc = s_kosmonaut_client_parse_response(response);
        zmsg_destroy(&response);
    }
        
    return rc;
}

int
kosmonaut_client_open_channel (kosmonaut_client_t* self,
                               const char* name,
                               int type)
{
    int rc = -1;
    zmsg_t* request;
    zmsg_t* response;
    
    assert(self);
    assert(name);
    
    request = zmsg_new();
    zmsg_addstr(request, name);

    response = s_kosmonaut_client_request(self, CMD_OPEN_CHANNEL, &request);
    
    if (response) {
        if (zmsg_size(response) >= 1)
            rc = s_kosmonaut_client_parse_response(response);
        zmsg_destroy(&response);
    }

    return rc;
}

int
kosmonaut_client_close_channel (kosmonaut_client_t* self,
                                const char* name)
{
    int rc = -1;
    zmsg_t* request;
    zmsg_t* response;
    
    assert(self);
    assert(name);
    
    request = zmsg_new();
    zmsg_addstr(request, name);
    
    response = s_kosmonaut_client_request(self, CMD_CLOSE_CHANNEL, &request);
    
    if (response) {
        if (zmsg_size(response) >= 1)
            rc = s_kosmonaut_client_parse_response(response);
        zmsg_destroy(&response);
    }

    return rc;
}

int
kosmonaut_client_request_single_access_token (kosmonaut_client_t* self,
                                              const char* permission,
                                              char** token)
{
    int rc = -1;
    zmsg_t* request;
    zmsg_t* response;
    
    assert(self);
    assert(permission);
    
    request = zmsg_new();
    zmsg_addstr(request, permission);
    
    response = s_kosmonaut_client_request(self, CMD_ACCESS_TOKEN, &request);

    if (response) {
        if (zmsg_size(response) == 2) {
            rc = s_kosmonaut_client_parse_response(response);
            if (rc == 0) {
                *token = zmsg_popstr(response);
            }
        }
        zmsg_destroy(&response);
    }

    return rc;
}

void
kosmonaut_client_destroy (kosmonaut_client_t** self_p)
{
    kosmonaut_client_t* self;

    if (self_p && *self_p) {
        self = *self_p;
        pthread_mutex_destroy(&self->mtx);
        zctx_destroy(&self->ctx);
        /* XXX: if we don't leak memory from the identity, then
           the ruby wrapper explodes... wtf? */
        /* free(self->identity); */
        free(self);
        *self_p = NULL;
    }
}

int
kosmonaut_client_test ()
{
    kosmonaut_client_t* c;
    int rc = 0;
    char* token = NULL;
    char* vhost_token = getenv("VHOST_TOKEN");
    c = kosmonaut_client_new("/test", vhost_token);
    if (!c) {
        printf("Expected to create a kosmonaut client instance\n");
        rc = -1;
        return rc;
    }
    rc = kosmonaut_client_connect(c, "tcp://127.0.0.1:8081");
    if (rc != 0) {
        printf("Expected to connect client\n");
        goto cleanup;
    }
    rc = kosmonaut_client_open_channel(c, "foo", 0);
    if (rc != 0) {
        printf("Expected to open channel\n");
        goto cleanup;
    }
    rc = kosmonaut_client_broadcast(c, "foo", "test", "{}");
    if (rc != 0) {
        printf("Expected to broadcast data on the channel\n");
        goto cleanup;
    }
    rc = kosmonaut_client_broadcast(c, "bar", "test", "{}");
    if (rc != 454) {
        rc = 0;
        printf("Expected to not broadcast on the non existing channel\n");
        goto cleanup;
    }
    rc = kosmonaut_client_close_channel(c, "foo");
    if (rc != 0) {
        printf("Expected to close channel\n");
        goto cleanup;
    }
    rc = kosmonaut_client_close_channel(c, "bar");
    if (rc != 454) {
        rc = 0;
        printf("Expected to not close non existing channel\n");
        goto cleanup;
    }
    rc = kosmonaut_client_request_single_access_token(c, ".*", &token);
    if (rc != 0) {
        printf("Expected to get a single access token\n");
        goto cleanup;
    }
    if (strlen(token) != 128) {
        printf("Expected to get a valid single access token\n");
        rc = -1;
        goto cleanup;
    }
 cleanup:
    if (token)
        free(token);
    kosmonaut_client_disconnect(c);
    kosmonaut_client_destroy(&c);
    return rc;
}
