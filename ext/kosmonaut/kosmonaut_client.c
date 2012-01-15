#include <ruby.h>
#include <kosmonaut.h>
#include <stdio.h>

static void
s_rb_kosmonaut_client_free (kosmonaut_client_t* client)
{
    if (client)
        kosmonaut_client_destroy(&client);
}

VALUE
rb_kosmonaut_client_new (VALUE class,
                         VALUE vhost,
                         VALUE secret)
{
    const char* _vhost = StringValuePtr(vhost);
    const char* _secret = StringValuePtr(secret);
    kosmonaut_client_t* ptr = kosmonaut_client_new(_vhost, _secret);
    VALUE self = Data_Wrap_Struct(class, 0, s_rb_kosmonaut_client_free, ptr);
    return self;
}

VALUE
rb_kosmonaut_client_connect (VALUE self,
                             VALUE addr)
{
    int rc;
    const char* _addr = StringValuePtr(addr);
    kosmonaut_client_t* client;
    Data_Get_Struct(self, kosmonaut_client_t, client);
    rc = kosmonaut_client_connect(client, _addr);
    return INT2FIX(rc);
}

VALUE
rb_kosmonaut_client_disconnect (VALUE self)
{
    kosmonaut_client_t* client;
    Data_Get_Struct(self, kosmonaut_client_t, client);
    kosmonaut_client_disconnect(client);
    return Qnil;
}

VALUE
rb_kosmonaut_client_broadcast (VALUE self,
                               VALUE channel,
                               VALUE event,
                               VALUE data)
{
    int rc;
    char* _channel = StringValuePtr(channel);
    char* _event = StringValuePtr(event);
    char* _data = StringValuePtr(data);
    kosmonaut_client_t* client;
    Data_Get_Struct(self, kosmonaut_client_t, client);
    rc = kosmonaut_client_broadcast(client, _channel, _event, _data);
    return INT2FIX(rc);
}

VALUE
rb_kosmonaut_client_open_channel (VALUE self,
                                  VALUE channel,
                                  VALUE type)
{
    int rc;
    char* _channel = StringValuePtr(channel);
    int _type = FIX2INT(type);
    kosmonaut_client_t* client;
    Data_Get_Struct(self, kosmonaut_client_t, client);
    rc = kosmonaut_client_open_channel(client, _channel, _type);
    return INT2FIX(rc);
}

VALUE
rb_kosmonaut_client_close_channel (VALUE self,
                                   VALUE channel)
{
    int rc;
    char* _channel = StringValuePtr(channel);
    kosmonaut_client_t* client;
    Data_Get_Struct(self, kosmonaut_client_t, client);
    rc = kosmonaut_client_close_channel(client, _channel);
    return INT2FIX(rc);
}

VALUE
rb_kosmonaut_client_request_single_access_token (VALUE self,
                                                 VALUE permission)
{
    VALUE result;
    int rc;
    char* token;
    char* _permission = StringValuePtr(permission);
    kosmonaut_client_t* client;
    Data_Get_Struct(self, kosmonaut_client_t, client);
    rc = kosmonaut_client_request_single_access_token(client, _permission, &token);
    if (rc == 0 && token) {
        result = rb_str_new2(token);
        free(token);
        return result;
    } else {
        return Qnil;
    }
}

void
Init_kosmonaut_client ()
{
    VALUE rb_mKosmonaut = rb_define_module("Kosmonaut");
    VALUE rb_cKosmonautClient = rb_define_class_under(rb_mKosmonaut, "Client", rb_cObject);

    rb_define_singleton_method(rb_cKosmonautClient, "new", rb_kosmonaut_client_new, 2);
    rb_define_method(rb_cKosmonautClient, "connect", rb_kosmonaut_client_connect, 1);
    rb_define_method(rb_cKosmonautClient, "disconnect", rb_kosmonaut_client_disconnect, 0);
    rb_define_method(rb_cKosmonautClient, "broadcast", rb_kosmonaut_client_broadcast, 3);
    rb_define_method(rb_cKosmonautClient, "open_channel", rb_kosmonaut_client_open_channel, 2);
    rb_define_method(rb_cKosmonautClient, "close_channel", rb_kosmonaut_client_close_channel, 1);
    rb_define_method(rb_cKosmonautClient, "request_single_access_token", rb_kosmonaut_client_request_single_access_token, 1);
}
