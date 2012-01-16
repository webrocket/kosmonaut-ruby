#include <assert.h>
#include <stdio.h>
#include <uuid/uuid.h>
#include <string.h>
#include <unistd.h>

#include "utils.h"
#include "kosmonaut.h"

#define HEARTBEAT_LIVENESS 3
#define DEFAULT_HEARTBEAT 2000
#define DEFAULT_RECONNECT 2000

void
s_kosmonaut_worker_send (kosmonaut_worker_t* self,
                         char* command,
                         zmsg_t** request_p)
{
    zmsg_t* request;

    assert(self);
    assert(command);
    pthread_mutex_lock(&self->mtx);

    request = request_p && *request_p ? *request_p : zmsg_new();
    zmsg_pushstr(request, command);
    /* XXX: no idea why, but DEALER's msg format is different from
       this send by REQ, so we have to add blank line here... */
    zmsg_pushstr(request, "");
    zmsg_send(&request, self->socket);
    
    pthread_mutex_unlock(&self->mtx);
}

kosmonaut_worker_t*
kosmonaut_worker_new (const char* vhost,
                      const char* secret)
{
    kosmonaut_worker_t* self;

    assert(vhost);
    assert(secret);

    self = (kosmonaut_worker_t*)malloc(sizeof(kosmonaut_worker_t));
    self->identity = generate_identity("dlr", vhost, secret);
    self->heartbeat = DEFAULT_HEARTBEAT;
    self->reconnect = DEFAULT_RECONNECT;
    self->addr = NULL;
    self->socket = NULL;
    self->ctx = zctx_new();
    pthread_mutex_init(&self->mtx, NULL);
    
    return self;
}

int
kosmonaut_worker_connect (kosmonaut_worker_t* self,
                          const char* addr)
{
    assert(self);
    assert(addr);

    self->addr = strdup(addr);
    return kosmonaut_worker_reconnect(self);
}

void
kosmonaut_worker_disconnect (kosmonaut_worker_t* self)
{
    assert(self);
    if (self->socket)
        zsocket_destroy(self->ctx, self->socket);
}

int
kosmonaut_worker_reconnect (kosmonaut_worker_t* self)
{
    int rc;

    assert(self);

    rc = 0;
    kosmonaut_worker_disconnect(self);
    self->socket = zsocket_new(self->ctx, ZMQ_DEALER);
    zsockopt_set_identity(self->socket, self->identity);

    rc = zsocket_connect(self->socket, self->addr);
    if (rc != 0)
        return rc;

    s_kosmonaut_worker_send(self, CMD_READY, NULL);
    self->liveness = HEARTBEAT_LIVENESS;
    self->heartbeat_at = zclock_time() + self->heartbeat;

    return rc;
}

int
kosmonaut_worker_listen (kosmonaut_worker_t* self,
                         kosmonaut_callback_t cb,
                         kosmonaut_error_callback_t errcb,
                         void* ptr)
{
    zmq_pollitem_t items[1];
    zframe_t* frame;
    zmsg_t* msg;
    int rc;
    char* errcstr;
    int errc;
        
    assert(self);
    self->alive = 1;
        
    while (1) {
        if (!self->alive) {
            s_kosmonaut_worker_send(self, CMD_QUIT, NULL);
            break;
        }
        
        items[0].socket = self->socket;
        items[0].events = ZMQ_POLLIN;
        rc = zmq_poll(items, 1, (self->heartbeat * 2) * ZMQ_POLL_MSEC);
        if (rc == -1)
            return -1;

        if (items[0].revents & ZMQ_POLLIN) {
            msg = zmsg_recv(self->socket);
            if (!msg)
                return -1;

            self->liveness = HEARTBEAT_LIVENESS;
            free(zmsg_popstr(msg)); /* Discarding empty line... */
            
            if (zmsg_size(msg) < 1)
                continue;

            frame = zmsg_pop(msg);

            if (zframe_streq(frame, CMD_HEARTBEAT)) {
                /* nothing to do for callback */
            } else if (zframe_streq(frame, CMD_QUIT)) {
                kosmonaut_worker_reconnect(self);
                break;
            } else if (zframe_streq(frame, CMD_TRIGGER)) {
                char* payload = zmsg_popstr(msg);
                cb(ptr, payload);
                free(payload);
            } else if (zframe_streq(frame, CMD_ERROR)) {
                if (zmsg_size(msg) < 1) {
                    errcb(self, 598); /* Internal error */
                } else {
                    errcstr = zmsg_popstr(msg);
                    sscanf(errcstr, "%d", &errc);
                    errcb(ptr, errc);
                    free(errcstr);
                    errc = 0;
                }
            } else {
                /* TODO: handle this error somehow... */
            }

            zframe_destroy(&frame);
            zmsg_destroy(&msg);
        } else if (--self->liveness == 0) {
            zclock_sleep(self->reconnect);
            kosmonaut_worker_reconnect(self);
        }
        if (zclock_time() > self->heartbeat_at) {
            s_kosmonaut_worker_send(self, CMD_HEARTBEAT, NULL);
            self->heartbeat_at = zclock_time() + self->heartbeat;
        }
    }

    return 0;
}

void
kosmonaut_worker_stop (kosmonaut_worker_t* self)
{
    assert(self);
    pthread_mutex_lock(&self->mtx);
    self->alive = 0;
    pthread_mutex_unlock(&self->mtx);
}

void
kosmonaut_worker_destroy (kosmonaut_worker_t** self_p)
{
    assert(self_p);
    if (*self_p) {
        kosmonaut_worker_t* self = *self_p;
        pthread_mutex_destroy(&self->mtx);
        zctx_destroy(&self->ctx);
        free(self->identity);
        free(self->addr);
        free(self);
        *self_p = NULL;
    }
}

static void
s_test_callback (void* self, char* data)
{}

static void
s_test_errcallback (void* self, unsigned int errcode)
{}

static void*
s_test_stop (void* worker_p)
{
    kosmonaut_worker_t* w;
    sleep(10);
    w = (kosmonaut_worker_t*)worker_p;
    kosmonaut_worker_stop(w);
    pthread_exit(NULL);
}

int
kosmonaut_worker_test ()
{
    kosmonaut_worker_t* w;
    int rc = 0;
    char* vhost_token = getenv("VHOST_TOKEN");
    pthread_t stop_action;

    w = kosmonaut_worker_new("/test", vhost_token);
    if (!w) {
        printf("Expected to create a kosmonaut worker instance\n");
        rc = -1;
        return rc;
    }
    rc = kosmonaut_worker_connect(w, "tcp://127.0.0.1:8081");
    if (rc != 0) {
        printf("Expected to connect worker\n");
        goto cleanup;
    }
    rc = pthread_create(&stop_action, NULL, s_test_stop, (void*)w);
    if (rc != 0) {
        printf("Expected to schedule listener's stop");
        goto cleanup;
    }
    rc = kosmonaut_worker_listen(w, s_test_callback, s_test_errcallback, NULL);
    if (rc != 0) {
        printf("Expected to connect worker\n");
        goto cleanup;
    }
 cleanup:
    kosmonaut_worker_disconnect(w);
    kosmonaut_worker_destroy(&w);
    return rc;
}
