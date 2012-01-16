#ifndef _KOSMONAUT_CLIENT_H_
#define _KOSMONAUT_CLIENT_H_

/**
 * WebRocket client (REQ) wrapper. The client is used to
 * trigger outgoing events, request authentication tokens
 * and manage channels on the fly.
 */
typedef struct kosmonaut_client_t {
    char* identity;
    void* socket;
    int res_timeout;
    int req_timeout;
    zctx_t* ctx;
    pthread_mutex_t mtx;
} kosmonaut_client_t;

/**
 * Kosmonaut REQ client constructor.
 * Creates a new instance of the `kosmonaut_client_t` - a wrapper
 * for 0MQ's REQ socket. Memory allocated by `kosmonaut_client_new`
 * have to be freed by the user using the `kosmonaut_client_destroy`
 * function.
 *
 * This function only creates and initializez client instance, it
 * doesn't connect to the server. To connect to the server you shall
 * use the `kosmonaut_client_connect` function.
 *
 * @see kosmonaut_client_destroy
 * @see kosmonaut_client_connect
 *
 * @param vhost Vhost to connect to
 * @param secret Secret key assigned to given vhost
 * @return Configured kosmonaut client instance
 */
kosmonaut_client_t*
kosmonaut_client_new(const char*, const char*);

/**
 * Kosmonaut client destructor.
 * Closes opened connection, cleans up 0MQ stuff and frees all
 * allocated memory.
 *
 * @param self_p Memory address of an kosmonaut client instance.
 */
void
kosmonaut_client_destroy(kosmonaut_client_t**);

/**
 * Connects to the server.
 * Setup 0MQ connection with the specified address.
 *
 * @param self A kosmonaut client instance
 * @param addr The server URI address
 * @return Status code - 0 if OK. 
 */
int
kosmonaut_client_connect(kosmonaut_client_t*, const char*);

/**
 * Disconnects from the server.
 * Closes OMQ connection with the server (if established).
 *
 * @param self A kosmonaut client instance
 */
void
kosmonaut_client_disconnect(kosmonaut_client_t*);

/**
 * Broadcasts data.
 * Broadcasts specified data attached to the event on the specified
 * channel. Channel must exists. To create a channel chec the
 * `kosmonaut_client_open_channel` function.
 *
 * @see kosmonaut_client_open_channel
 *
 * @param self A kosmonaut client instance
 * @param channel Name of the channel to broadcast on
 * @param event Name of the event to trigger
 * @param data JSON-serialized data attached to the event's payload
 * @return Status code - 0 if OK
 */
int
kosmonaut_client_broadcast(kosmonaut_client_t*, const char*, const char*, const char*);

/**
 * Creates new channel.
 * Creates a channel with the specified name.
 *
 * @see kosmonaut_client_close_channel
 *
 * @param self A kosmonaut client instance
 * @param name Name of the created channel
 * @param type A type of the channel (0 - normal, 1 - private, 2 - presence)
 * @return Status code - 0 if OK
 */
int
kosmonaut_client_open_channel(kosmonaut_client_t* self, const char*, int);

/**
 * Deletes channel.
 * Removes a channel with the specified name if such one exists.
 *
 * @see kosmonaut_client_open_channel
 *
 * @param self A kosmonaut client instance
 * @param name Name of the closed channel
 * @return Status code - 0 if OK
 */
int
kosmonaut_client_close_channel(kosmonaut_client_t* self, const char*);

/**
 * Gets a single access token.
 * Requests for a single access token which can be used for frontend
 * connection to authenticate on presence/private channel.
 *
 * @param self A kosmonaut client instance
 * @param permission A permission regexp
 * @param token Result will be written here
 * @return Status code - 0 if ok
 */
int
kosmonaut_client_request_single_access_token(kosmonaut_client_t*, const char*, char**);

/**
 * Kosmonaut client's self test.
 */
int
kosmonaut_client_test();

#endif /* _KOSMONAUT_CLIENT_H_ */
