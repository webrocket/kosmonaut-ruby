#ifndef _KOSMONAUT_WORKER_H_
#define _KOSMONAUT_WORKER_H_

/**
 * WebRocket worker (DEALER) wrapper. The worker is used to
 * listen for the incoming events.
 */
typedef struct kosmonaut_worker_t {
    char* addr;
    char* identity;
    void* socket;
    uint64_t heartbeat_at;
    size_t liveness;
    int heartbeat;
    int reconnect;
    unsigned short int alive;
    zctx_t* ctx;
    pthread_mutex_t mtx;
} kosmonaut_worker_t;

/**
 * Listener's callback function type. Incoming events should
 * be handled by a callback of that type. Function takes two
 * arguments, worker instance and received payload (which
 * shall be a JSON-serialized string).
 */
typedef void(*kosmonaut_callback_t)(void*, char*);

/**
 * Listener's error callback function type.
 */
typedef void(*kosmonaut_error_callback_t)(void*, unsigned int);

/**
 * Kosmonaut DEALER worker constructor.
 * Creates a new instance of the `kosmonaut_worker_t` - a wrapper
 * for 0MQ's DEALER socket. Memory allocated by `kosmonaut_worker_new`
 * have to be freed by the user using the `kosmonaut_worker_destroy`
 * function.
 *
 * This function only creates and initializez client instance, it
 * doesn't connect to the server. To connect to the server you shall
 * use the `kosmonaut_worker_connect` function.
 *
 * @see kosmonaut_worker_destroy
 * @see kosmonaut_worker_connect
 *
 * @param vhost Vhost to connect to
 * @param secret Secret key assigned to given vhost
 * @return Configured kosmonaut worker instance
 */
kosmonaut_worker_t*
kosmonaut_worker_new(const char*, const char*);

/**
 * Kosmonaut worker destructor.
 * Closes opened connection, cleans up 0MQ stuff and frees all
 * allocated memory.
 *
 * @param self_p Memory address of an kosmonaut worker instance.
 */
void
kosmonaut_worker_destroy(kosmonaut_worker_t**);

/**
 * Connects to the server.
 * Setup 0MQ connection with the specified address.
 *
 * @param self A kosmonaut worker instance
 * @param addr The server URI address
 * @return Status code - 0 if OK. 
 */
int
kosmonaut_worker_connect(kosmonaut_worker_t*, const char*);

/**
 * Disconnects from the server.
 * Closes OMQ connection with the server (if established).
 *
 * @param self A kosmonaut worker instance
 */
void
kosmonaut_worker_disconnect(kosmonaut_worker_t*);

/**
 * Restarts connection..
 * Closes OMQ connection with the server (if established) and
 * tries to connect again.
 *
 * @param self A kosmonaut worker instance
 */
int
kosmonaut_worker_reconnect(kosmonaut_worker_t*);

/**
 * Starts listener.
 * Starts a listener's event loop and handles all message incoming
 * from the WebRocket server. This function should be called in
 * separate thread, and it's execution terminated using the
 * `kosmonaut_worker_stop` function. 
 *
 * @see kosmonaut_worker_stop
 *
 * @param self A kosmonaut worker instance.
 * @param cb Callback function called when trigger command is received
 * @param errdb Callback function called when error encountered
 * @param ptr Extra parameter passed to callbacks
 * @return Status code - 0 if OK
 */
int
kosmonaut_worker_listen(kosmonaut_worker_t*, kosmonaut_callback_t, kosmonaut_error_callback_t, void*);

/**
 * Stops listener.
 * Marks worker as dead and closes the listener's loop previously
 * started by the `kosmonaut_worker_listen` function.
 *
 * @see kosmonaut_worker_listen
 *
 * @param self A kosmonaut worker instance.
 */
void
kosmonaut_worker_stop(kosmonaut_worker_t*);

/**
 * Kosmonaut worker's self test.
 */
int
kosmonaut_worker_test();

#endif /* _KOSMONAUT_WORKER_H_ */
