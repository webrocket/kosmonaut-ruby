#include <uuid/uuid.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define UUIDSTR_SIZE 36

char*
generate_identity (const char* type,
                   const char* vhost,
                   const char* secret)
{
    int identity_len = strlen(type) + strlen(vhost) + strlen(secret) + UUIDSTR_SIZE + 3;
    char* identity = (char*)malloc(identity_len * sizeof(char));
    char* sessid = (char*)malloc(UUIDSTR_SIZE * sizeof(char));
    uuid_t uuid;

    uuid_generate(uuid);
    uuid_unparse_lower(uuid, sessid);
    sprintf(identity, "%s:%s:%s:%s", type, vhost, secret, sessid);

    uuid_clear(uuid);
    free(sessid);

    return identity;
}
