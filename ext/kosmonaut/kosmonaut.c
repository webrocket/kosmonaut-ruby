#include "kosmonaut_client.h"
#include "kosmonaut_worker.h"

void
Init_kosmonaut_ext()
{
    Init_kosmonaut_client();
    Init_kosmonaut_worker();
}