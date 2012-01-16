/*#include <uuid/uuid.h>*/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <assert.h>

#define SESSID_SIZE 35

char*
generate_identity (const char* type,
                   const char* vhost,
                   const char* secret)
{
    int i = 0;
    int identity_len = strlen(type) + strlen(vhost) + strlen(secret) + SESSID_SIZE + 3;
    char* identity = (char*)malloc(identity_len * sizeof(char));
    char* sessid = (char*)malloc(SESSID_SIZE * sizeof(char));
    FILE* randdata = fopen("/dev/urandom", "rb");

    assert(randdata);
    while (i < SESSID_SIZE) {
        unsigned short c = fgetc(randdata);
        sprintf(sessid + i, "%x", c);
        i += 1;
    }
    
    sprintf(identity, "%s:%s:%s:%s", type, vhost, secret, sessid);
    fclose(randdata);
    free(sessid);

    return identity;
}
