#ifndef _UTILS_H_
#define _UTILS_H_

/*
 * Generates an unique identity for specified socket type.
 *
 * @param type - socket type
 * @param vhost - vhost for which identity should be generated
 * @param secret - vhost's access token
 * @return client's unique identity
 */
char* 
generate_identity(const char*, const char*, const char*);

#endif /* _UTILS_H_ */
