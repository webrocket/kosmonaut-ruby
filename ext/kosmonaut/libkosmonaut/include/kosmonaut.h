#ifndef _KOSMONAUT_H_
#define _KOSMONAUT_H_

#include <pthread.h>
#include <czmq.h>

#include "kosmonaut/worker.h"
#include "kosmonaut/client.h"

/* Protocol commands */
#define CMD_OK            "OK"
#define CMD_ERROR         "ER"
#define CMD_BROADCAST     "BC"
#define CMD_OPEN_CHANNEL  "OC"
#define CMD_CLOSE_CHANNEL "CC"
#define CMD_ACCESS_TOKEN  "AT"
#define CMD_HEARTBEAT     "HB"
#define CMD_READY         "RD"
#define CMD_TRIGGER       "TR"
#define CMD_QUIT          "QT"

#endif /* _KOSMONAUT_H_ */
