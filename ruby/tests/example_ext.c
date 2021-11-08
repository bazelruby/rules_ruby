#include <ruby/ruby.h>
#include <ruby/core/rbasic.h>

static VALUE show_version(VALUE self) {
  ruby_show_version();
  return Qnil;
}

void Init_example_ext(void) {
  rb_define_global_function("show_version", show_version, 0);
}
