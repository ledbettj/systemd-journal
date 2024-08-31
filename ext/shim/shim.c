#include "shim.h"

VALUE rb_mShim;

VALUE shim_free(VALUE self, VALUE ptr);

RUBY_FUNC_EXPORTED void
Init_shim(void)
{
  VALUE mSystemd = rb_define_module("Systemd");
  VALUE cJournal = rb_define_class_under(mSystemd, "Journal", rb_cObject);
  rb_mShim = rb_define_module_under(cJournal, "Shim");

  rb_define_module_function(rb_mShim, "free", shim_free, 1);
}

VALUE shim_free(VALUE self, VALUE ptr) {
  VALUE rb_addr = rb_funcall(ptr, rb_intern("address"), 0);
  void* addr = (void*)NUM2ULL(rb_addr);
  if (addr) {
    free(addr);
  }

  return Qnil;
}
