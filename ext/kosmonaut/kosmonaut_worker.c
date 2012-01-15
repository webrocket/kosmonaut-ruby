#include <ruby.h>
#include <kosmonaut.h>
#include <stdio.h>

static void
s_rb_kosmonaut_worker_on_message (void* ptr, char* data)
{
    VALUE worker = (VALUE)ptr;
    VALUE argv[1];
    argv[0] = rb_str_new2(data);
    rb_funcall(worker, rb_intern("_on_message"), 1, argv);
}

static void
s_rb_kosmonaut_worker_on_error(void* ptr, unsigned int code)
{
    VALUE worker = (VALUE)ptr;
    VALUE argv[1];
    argv[0] = INT2FIX(code);
    rb_funcall(worker, rb_intern("_on_error"), 1, argv);    
}

static void
s_rb_kosmonaut_worker_free (kosmonaut_worker_t* worker)
{
    if (worker)
        kosmonaut_worker_destroy(&worker);
}

VALUE
rb_kosmonaut_worker_new (VALUE class,
                         VALUE vhost,
                         VALUE secret)
{
    const char* _vhost = StringValuePtr(vhost);
    const char* _secret = StringValuePtr(secret);
    kosmonaut_worker_t* ptr = kosmonaut_worker_new(_vhost, _secret);
    VALUE self = Data_Wrap_Struct(class, 0, s_rb_kosmonaut_worker_free, ptr);
    rb_obj_call_init(self, 0, NULL);
    return self;
}

VALUE
rb_kosmonaut_worker_init (VALUE self)
{
    return Qnil;
}

VALUE
rb_kosmonaut_worker_connect (VALUE self,
                             VALUE addr)
{
    int rc;
    const char* _addr = StringValuePtr(addr);
    kosmonaut_worker_t* worker;
    Data_Get_Struct(self, kosmonaut_worker_t, worker);
    rc = kosmonaut_worker_connect(worker, _addr);
    return INT2FIX(rc);
}

VALUE
rb_kosmonaut_worker_disconnect (VALUE self)
{
    kosmonaut_worker_t* worker;
    Data_Get_Struct(self, kosmonaut_worker_t, worker);
    kosmonaut_worker_disconnect(worker);
    return Qnil;
}

VALUE
rb_kosmonaut_worker_stop (VALUE self)
{
    kosmonaut_worker_t* worker;
    Data_Get_Struct(self, kosmonaut_worker_t, worker);
    kosmonaut_worker_stop(worker);
    return Qnil;
}


VALUE
rb_kosmonaut_worker_listen (VALUE self)
{
    int rc;
    kosmonaut_worker_t* worker;
    Data_Get_Struct(self, kosmonaut_worker_t, worker);
    rc = kosmonaut_worker_listen(worker, s_rb_kosmonaut_worker_on_message, s_rb_kosmonaut_worker_on_error, (void*)self);
    return INT2FIX(rc);
}

VALUE
rb_kosmonaut_worker_on_message (VALUE self,
                                VALUE data)
{
    return Qnil;
}

VALUE
rb_kosmonaut_worker_on_error (VALUE self,
                              VALUE errcode)
{
    return Qnil;
}

void
Init_kosmonaut_worker ()
{
    VALUE rb_mKosmonaut = rb_define_module("Kosmonaut");
    VALUE rb_mKosmonautC = rb_define_module_under(rb_mKosmonaut, "C");
    VALUE rb_cKosmonautWorker = rb_define_class_under(rb_mKosmonautC, "Worker", rb_cObject);

    rb_define_singleton_method(rb_cKosmonautWorker, "new", rb_kosmonaut_worker_new, 2);
    rb_define_method(rb_cKosmonautWorker, "initialize", rb_kosmonaut_worker_init, 0);
    rb_define_method(rb_cKosmonautWorker, "connect", rb_kosmonaut_worker_connect, 1);
    rb_define_method(rb_cKosmonautWorker, "disconnect", rb_kosmonaut_worker_disconnect, 0);
    rb_define_method(rb_cKosmonautWorker, "stop", rb_kosmonaut_worker_stop, 0);
    rb_define_method(rb_cKosmonautWorker, "listen", rb_kosmonaut_worker_listen, 0);
    rb_define_method(rb_cKosmonautWorker, "_on_message", rb_kosmonaut_worker_on_message, 1);
    rb_define_method(rb_cKosmonautWorker, "_on_error", rb_kosmonaut_worker_on_error, 1);
}
