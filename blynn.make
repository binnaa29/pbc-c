# I use this Makefile rather than the autotools for simplicity and speed.
# Of course, it is less portable. Much of it is due to Hovav Shacham.

.PHONY: target binaries test clean depend

target: out libpbc.a binaries

CC := gcc
RANLIB := ranlib
warnflags := -Wall -W -Wfloat-equal -Wendif-labels -Wshadow \
	     -Wpointer-arith -Wcast-align -Wstrict-prototypes \
             -Wredundant-decls #-std=c99 -pedantic
CPPFLAGS := -Iinclude
optflags := -O3 -g -pipe -ffast-math -fomit-frame-pointer
LDLIBS := -lgmp -lm
CFLAGS := $(optflags) $(warnflags)

ifeq ($(PLATFORM),win32)
  nonlinux := .win32
  exe_suffix := .exe
  CC := i586-mingw32msvc-gcc
  AR := i586-mingw32msvc-ar
  RANLIB := i586-mingw32msvc-ranlib
  CPPFLAGS := $(CPPFLAGS) -I/home/blynn/cross/gmp/include
  LDFLAGS := -L/home/blynn/cross/gmp/lib
  pbc_getline_objs := pbc/pbc_getline.o
else
  # tcmalloc is faster than normal malloc.
  LDLIBS := $(LDLIBS) -ltcmalloc
  pbc_getline_objs := pbc/pbc_getline.readline.o
  pbc_pbc_libs := -lreadline
endif

libpbc_srcs := \
  $(addsuffix .c,$(addprefix arith/, \
    field fp montfp naivefp fastfp fasterfp fieldmpz fieldquadratic poly \
    random dlog)) \
  $(addsuffix .c,$(addprefix ecc/, \
    curve singular pairing param_io \
    a_param d_param e_param f_param g_param \
    hilbert mnt mpc)) \
  $(addsuffix .c,$(addprefix misc/, \
    utils \
    darray symtab \
    extend_printf memory)) \
  $(addsuffix $(nonlinux).c,misc/get_time arith/init_random)

libpbc_objs := $(libpbc_srcs:.c=.o)

bin_srcs := \
  $(addsuffix .c,$(addprefix example/, \
    bls hess joux paterson yuanli zhangkim zss)) \
  $(addsuffix .c,$(addprefix gen/, \
    gena1param genaparam gendparam geneparam genfparam gengparam \
    hilbertpoly listmnt listfreeman)) \
  benchmark/benchmark.c benchmark/timersa.c benchmark/ellnet.c

define demo_tmpl
  examples += out/$(basename $(notdir $(1)))$(exe_suffix)
  out/$(basename $(notdir $(1)))$(exe_suffix) : $(1) libpbc.a ; \
    $(CC) -o $$@ $(LDFLAGS) $$^ $(LOADLIBES) $(LDLIBS)
endef

$(foreach x,$(bin_srcs:.c=.o),$(eval $(call demo_tmpl,$(x))))

pbc_objs := pbc/pbc.o $(pbc_getline_objs)

pbc_bin := out/pbc$(exe_suffix)
$(pbc_bin) : $(pbc_objs) libpbc.a
	$(CC) -o $@ $(LDFLAGS) $^ $(LOADLIBES) $(LDLIBS) $(pbc_pbc_libs)

binaries : $(examples) $(pbc_bin)

test_srcs := \
  $(addsuffix .c,$(addprefix guru/, \
    fp_test quadratic_test poly_test exp_test pairing_test))

tests := $(test_srcs:.c=)

# Object files needed to test Fp.
fp_objs := $(addsuffix .o, \
  arith/field arith/fp arith/naivefp arith/fastfp arith/fasterfp arith/montfp arith/random arith/init_random misc/extend_printf misc/memory misc/utils)

guru/exp_test: guru/exp_test.o libpbc.a
guru/pairing_test: guru/pairing_test.o libpbc.a
guru/fp_test: guru/fp_test.o $(fp_objs)
guru/poly_test: guru/poly_test.o $(fp_objs) arith/poly.o misc/darray.o
guru/quadratic_test: guru/quadratic_test.o $(fp_objs) arith/fieldquadratic.o

test : $(tests)

out: ; mkdir out

srcs := $(libpbc_srcs) $(bin_srcs) $(test_srcs)
objs := $(srcs:.c=.o) $(pbc_objs)

clean: ; -rm -r out $(objs) libpbc.a

# File dependencies for library-making.
# See GNU Make manual, sect. 11.2.
libpbc.a: libpbc.a($(libpbc_objs))
	$(RANLIB) $@

depend:
	makedepend -fblynn.make -Iinclude -Y -- $(CFLAGS) -- $(srcs) 2> /dev/null

# DO NOT DELETE

arith/field.o: include/pbc_utils.h include/pbc_field.h include/pbc_memory.h
arith/fp.o: include/pbc_utils.h include/pbc_field.h include/pbc_fp.h
arith/fp.o: include/pbc_memory.h
arith/montfp.o: include/pbc_utils.h include/pbc_field.h include/pbc_random.h
arith/montfp.o: include/pbc_fp.h include/pbc_memory.h
arith/naivefp.o: include/pbc_utils.h include/pbc_field.h include/pbc_random.h
arith/naivefp.o: include/pbc_fp.h include/pbc_memory.h
arith/fastfp.o: include/pbc_utils.h include/pbc_field.h include/pbc_random.h
arith/fastfp.o: include/pbc_fp.h include/pbc_memory.h
arith/fasterfp.o: include/pbc_utils.h include/pbc_field.h
arith/fasterfp.o: include/pbc_random.h include/pbc_fp.h include/pbc_memory.h
arith/fieldmpz.o: include/pbc_utils.h include/pbc_field.h
arith/fieldmpz.o: include/pbc_random.h include/pbc_fp.h include/pbc_memory.h
arith/fieldquadratic.o: include/pbc_utils.h include/pbc_field.h
arith/fieldquadratic.o: include/pbc_fieldquadratic.h include/pbc_memory.h
arith/poly.o: include/pbc_utils.h include/pbc_field.h include/pbc_darray.h
arith/poly.o: include/pbc_poly.h include/pbc_memory.h
arith/random.o: include/pbc_random.h include/pbc_utils.h include/pbc_memory.h
arith/dlog.o: include/pbc_utils.h include/pbc_darray.h include/pbc_field.h
arith/dlog.o: include/pbc_memory.h
ecc/curve.o: include/pbc_utils.h include/pbc_field.h include/pbc_darray.h
ecc/curve.o: include/pbc_poly.h include/pbc_curve.h include/pbc_memory.h
ecc/curve.o: include/pbc_random.h
ecc/singular.o: include/pbc_utils.h include/pbc_field.h include/pbc_curve.h
ecc/singular.o: include/pbc_param.h include/pbc_pairing.h include/pbc_fp.h
ecc/singular.o: include/pbc_memory.h
ecc/pairing.o: include/pbc_utils.h include/pbc_field.h include/pbc_darray.h
ecc/pairing.o: include/pbc_poly.h include/pbc_curve.h include/pbc_param.h
ecc/pairing.o: include/pbc_pairing.h include/pbc_memory.h
ecc/param_io.o: include/pbc_utils.h include/pbc_symtab.h include/pbc_darray.h
ecc/param_io.o: include/pbc_memory.h ecc/param_io.h include/pbc_param.h
ecc/param_io.o: include/pbc_a_param.h include/pbc_mnt.h include/pbc_d_param.h
ecc/param_io.o: include/pbc_e_param.h include/pbc_f_param.h
ecc/param_io.o: include/pbc_a1_param.h include/pbc_g_param.h
ecc/a_param.o: include/pbc_utils.h include/pbc_field.h include/pbc_fp.h
ecc/a_param.o: include/pbc_fieldquadratic.h include/pbc_param.h
ecc/a_param.o: include/pbc_pairing.h include/pbc_curve.h include/pbc_random.h
ecc/a_param.o: include/pbc_memory.h ecc/param_io.h include/pbc_a_param.h
ecc/a_param.o: include/pbc_a1_param.h
ecc/d_param.o: include/pbc_utils.h include/pbc_darray.h include/pbc_field.h
ecc/d_param.o: include/pbc_poly.h include/pbc_fp.h
ecc/d_param.o: include/pbc_fieldquadratic.h include/pbc_hilbert.h
ecc/d_param.o: include/pbc_mnt.h include/pbc_curve.h include/pbc_param.h
ecc/d_param.o: include/pbc_pairing.h include/pbc_memory.h
ecc/d_param.o: include/pbc_d_param.h ecc/param_io.h
ecc/e_param.o: include/pbc_utils.h include/pbc_field.h include/pbc_fp.h
ecc/e_param.o: include/pbc_param.h include/pbc_pairing.h include/pbc_curve.h
ecc/e_param.o: include/pbc_random.h include/pbc_memory.h
ecc/e_param.o: include/pbc_e_param.h ecc/param_io.h
ecc/f_param.o: include/pbc_utils.h include/pbc_field.h include/pbc_fp.h
ecc/f_param.o: include/pbc_fieldquadratic.h include/pbc_param.h
ecc/f_param.o: include/pbc_pairing.h include/pbc_poly.h include/pbc_curve.h
ecc/f_param.o: include/pbc_memory.h include/pbc_f_param.h ecc/param_io.h
ecc/g_param.o: include/pbc_utils.h include/pbc_darray.h include/pbc_field.h
ecc/g_param.o: include/pbc_poly.h include/pbc_fp.h
ecc/g_param.o: include/pbc_fieldquadratic.h include/pbc_hilbert.h
ecc/g_param.o: include/pbc_mnt.h include/pbc_curve.h include/pbc_param.h
ecc/g_param.o: include/pbc_pairing.h include/pbc_memory.h
ecc/g_param.o: include/pbc_g_param.h ecc/param_io.h
ecc/hilbert.o: include/pbc_utils.h include/pbc_field.h include/pbc_darray.h
ecc/hilbert.o: include/pbc_poly.h include/pbc_hilbert.h include/pbc_mpc.h
ecc/hilbert.o: include/pbc_memory.h
ecc/mnt.o: include/pbc_darray.h include/pbc_mnt.h include/pbc_memory.h
ecc/mnt.o: include/pbc_utils.h
ecc/mpc.o: include/pbc_darray.h include/pbc_mpc.h
misc/utils.o: include/pbc_utils.h include/pbc_field.h
misc/darray.o: include/pbc_darray.h include/pbc_memory.h
misc/symtab.o: include/pbc_symtab.h include/pbc_darray.h include/pbc_memory.h
misc/extend_printf.o: include/pbc_utils.h include/pbc_field.h
misc/extend_printf.o: include/pbc_memory.h
misc/memory.o: include/pbc_utils.h include/pbc_memory.h
arith/init_random.o: include/pbc_utils.h include/pbc_random.h
example/bls.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
example/bls.o: include/pbc_param.h include/pbc_pairing.h include/pbc_curve.h
example/bls.o: include/pbc_mnt.h include/pbc_a1_param.h include/pbc_a_param.h
example/bls.o: include/pbc_d_param.h include/pbc_e_param.h
example/bls.o: include/pbc_f_param.h include/pbc_g_param.h
example/bls.o: include/pbc_random.h include/pbc_memory.h example/demo.h
example/hess.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
example/hess.o: include/pbc_param.h include/pbc_pairing.h include/pbc_curve.h
example/hess.o: include/pbc_mnt.h include/pbc_a1_param.h
example/hess.o: include/pbc_a_param.h include/pbc_d_param.h
example/hess.o: include/pbc_e_param.h include/pbc_f_param.h
example/hess.o: include/pbc_g_param.h include/pbc_random.h
example/hess.o: include/pbc_memory.h include/pbc_time.h example/demo.h
example/joux.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
example/joux.o: include/pbc_param.h include/pbc_pairing.h include/pbc_curve.h
example/joux.o: include/pbc_mnt.h include/pbc_a1_param.h
example/joux.o: include/pbc_a_param.h include/pbc_d_param.h
example/joux.o: include/pbc_e_param.h include/pbc_f_param.h
example/joux.o: include/pbc_g_param.h include/pbc_random.h
example/joux.o: include/pbc_memory.h include/pbc_time.h example/demo.h
example/paterson.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
example/paterson.o: include/pbc_param.h include/pbc_pairing.h
example/paterson.o: include/pbc_curve.h include/pbc_mnt.h
example/paterson.o: include/pbc_a1_param.h include/pbc_a_param.h
example/paterson.o: include/pbc_d_param.h include/pbc_e_param.h
example/paterson.o: include/pbc_f_param.h include/pbc_g_param.h
example/paterson.o: include/pbc_random.h include/pbc_memory.h
example/paterson.o: include/pbc_time.h example/demo.h
example/yuanli.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
example/yuanli.o: include/pbc_param.h include/pbc_pairing.h
example/yuanli.o: include/pbc_curve.h include/pbc_mnt.h
example/yuanli.o: include/pbc_a1_param.h include/pbc_a_param.h
example/yuanli.o: include/pbc_d_param.h include/pbc_e_param.h
example/yuanli.o: include/pbc_f_param.h include/pbc_g_param.h
example/yuanli.o: include/pbc_random.h include/pbc_memory.h
example/yuanli.o: include/pbc_time.h example/demo.h
example/zhangkim.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
example/zhangkim.o: include/pbc_param.h include/pbc_pairing.h
example/zhangkim.o: include/pbc_curve.h include/pbc_mnt.h
example/zhangkim.o: include/pbc_a1_param.h include/pbc_a_param.h
example/zhangkim.o: include/pbc_d_param.h include/pbc_e_param.h
example/zhangkim.o: include/pbc_f_param.h include/pbc_g_param.h
example/zhangkim.o: include/pbc_random.h include/pbc_memory.h
example/zhangkim.o: include/pbc_time.h example/demo.h
example/zss.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
example/zss.o: include/pbc_param.h include/pbc_pairing.h include/pbc_curve.h
example/zss.o: include/pbc_mnt.h include/pbc_a1_param.h include/pbc_a_param.h
example/zss.o: include/pbc_d_param.h include/pbc_e_param.h
example/zss.o: include/pbc_f_param.h include/pbc_g_param.h
example/zss.o: include/pbc_random.h include/pbc_memory.h include/pbc_time.h
example/zss.o: example/demo.h
gen/gena1param.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
gen/gena1param.o: include/pbc_param.h include/pbc_pairing.h
gen/gena1param.o: include/pbc_curve.h include/pbc_mnt.h
gen/gena1param.o: include/pbc_a1_param.h include/pbc_a_param.h
gen/gena1param.o: include/pbc_d_param.h include/pbc_e_param.h
gen/gena1param.o: include/pbc_f_param.h include/pbc_g_param.h
gen/gena1param.o: include/pbc_random.h include/pbc_memory.h
gen/genaparam.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
gen/genaparam.o: include/pbc_param.h include/pbc_pairing.h
gen/genaparam.o: include/pbc_curve.h include/pbc_mnt.h include/pbc_a1_param.h
gen/genaparam.o: include/pbc_a_param.h include/pbc_d_param.h
gen/genaparam.o: include/pbc_e_param.h include/pbc_f_param.h
gen/genaparam.o: include/pbc_g_param.h include/pbc_random.h
gen/genaparam.o: include/pbc_memory.h
gen/gendparam.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
gen/gendparam.o: include/pbc_param.h include/pbc_pairing.h
gen/gendparam.o: include/pbc_curve.h include/pbc_mnt.h include/pbc_a1_param.h
gen/gendparam.o: include/pbc_a_param.h include/pbc_d_param.h
gen/gendparam.o: include/pbc_e_param.h include/pbc_f_param.h
gen/gendparam.o: include/pbc_g_param.h include/pbc_random.h
gen/gendparam.o: include/pbc_memory.h
gen/geneparam.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
gen/geneparam.o: include/pbc_param.h include/pbc_pairing.h
gen/geneparam.o: include/pbc_curve.h include/pbc_mnt.h include/pbc_a1_param.h
gen/geneparam.o: include/pbc_a_param.h include/pbc_d_param.h
gen/geneparam.o: include/pbc_e_param.h include/pbc_f_param.h
gen/geneparam.o: include/pbc_g_param.h include/pbc_random.h
gen/geneparam.o: include/pbc_memory.h
gen/genfparam.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
gen/genfparam.o: include/pbc_param.h include/pbc_pairing.h
gen/genfparam.o: include/pbc_curve.h include/pbc_mnt.h include/pbc_a1_param.h
gen/genfparam.o: include/pbc_a_param.h include/pbc_d_param.h
gen/genfparam.o: include/pbc_e_param.h include/pbc_f_param.h
gen/genfparam.o: include/pbc_g_param.h include/pbc_random.h
gen/genfparam.o: include/pbc_memory.h
gen/gengparam.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
gen/gengparam.o: include/pbc_param.h include/pbc_pairing.h
gen/gengparam.o: include/pbc_curve.h include/pbc_mnt.h include/pbc_a1_param.h
gen/gengparam.o: include/pbc_a_param.h include/pbc_d_param.h
gen/gengparam.o: include/pbc_e_param.h include/pbc_f_param.h
gen/gengparam.o: include/pbc_g_param.h include/pbc_random.h
gen/gengparam.o: include/pbc_memory.h
gen/hilbertpoly.o: include/pbc_utils.h include/pbc_field.h
gen/hilbertpoly.o: include/pbc_darray.h include/pbc_poly.h
gen/hilbertpoly.o: include/pbc_hilbert.h
gen/listmnt.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
gen/listmnt.o: include/pbc_param.h include/pbc_pairing.h include/pbc_curve.h
gen/listmnt.o: include/pbc_mnt.h include/pbc_a1_param.h include/pbc_a_param.h
gen/listmnt.o: include/pbc_d_param.h include/pbc_e_param.h
gen/listmnt.o: include/pbc_f_param.h include/pbc_g_param.h
gen/listmnt.o: include/pbc_random.h include/pbc_memory.h
gen/listfreeman.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
gen/listfreeman.o: include/pbc_param.h include/pbc_pairing.h
gen/listfreeman.o: include/pbc_curve.h include/pbc_mnt.h
gen/listfreeman.o: include/pbc_a1_param.h include/pbc_a_param.h
gen/listfreeman.o: include/pbc_d_param.h include/pbc_e_param.h
gen/listfreeman.o: include/pbc_f_param.h include/pbc_g_param.h
gen/listfreeman.o: include/pbc_random.h include/pbc_memory.h
benchmark/benchmark.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
benchmark/benchmark.o: include/pbc_param.h include/pbc_pairing.h
benchmark/benchmark.o: include/pbc_curve.h include/pbc_mnt.h
benchmark/benchmark.o: include/pbc_a1_param.h include/pbc_a_param.h
benchmark/benchmark.o: include/pbc_d_param.h include/pbc_e_param.h
benchmark/benchmark.o: include/pbc_f_param.h include/pbc_g_param.h
benchmark/benchmark.o: include/pbc_random.h include/pbc_memory.h
benchmark/benchmark.o: include/pbc_time.h example/demo.h
benchmark/timersa.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
benchmark/timersa.o: include/pbc_param.h include/pbc_pairing.h
benchmark/timersa.o: include/pbc_curve.h include/pbc_mnt.h
benchmark/timersa.o: include/pbc_a1_param.h include/pbc_a_param.h
benchmark/timersa.o: include/pbc_d_param.h include/pbc_e_param.h
benchmark/timersa.o: include/pbc_f_param.h include/pbc_g_param.h
benchmark/timersa.o: include/pbc_random.h include/pbc_memory.h
benchmark/timersa.o: include/pbc_fp.h include/pbc_time.h
benchmark/ellnet.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
benchmark/ellnet.o: include/pbc_param.h include/pbc_pairing.h
benchmark/ellnet.o: include/pbc_curve.h include/pbc_mnt.h
benchmark/ellnet.o: include/pbc_a1_param.h include/pbc_a_param.h
benchmark/ellnet.o: include/pbc_d_param.h include/pbc_e_param.h
benchmark/ellnet.o: include/pbc_f_param.h include/pbc_g_param.h
benchmark/ellnet.o: include/pbc_random.h include/pbc_memory.h
benchmark/ellnet.o: include/pbc_time.h example/demo.h
guru/fp_test.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
guru/fp_test.o: include/pbc_param.h include/pbc_pairing.h include/pbc_curve.h
guru/fp_test.o: include/pbc_mnt.h include/pbc_a1_param.h
guru/fp_test.o: include/pbc_a_param.h include/pbc_d_param.h
guru/fp_test.o: include/pbc_e_param.h include/pbc_f_param.h
guru/fp_test.o: include/pbc_g_param.h include/pbc_random.h
guru/fp_test.o: include/pbc_memory.h include/pbc_fp.h guru/test.h
guru/quadratic_test.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
guru/quadratic_test.o: include/pbc_param.h include/pbc_pairing.h
guru/quadratic_test.o: include/pbc_curve.h include/pbc_mnt.h
guru/quadratic_test.o: include/pbc_a1_param.h include/pbc_a_param.h
guru/quadratic_test.o: include/pbc_d_param.h include/pbc_e_param.h
guru/quadratic_test.o: include/pbc_f_param.h include/pbc_g_param.h
guru/quadratic_test.o: include/pbc_random.h include/pbc_memory.h
guru/quadratic_test.o: include/pbc_fp.h include/pbc_fieldquadratic.h
guru/quadratic_test.o: guru/test.h
guru/poly_test.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
guru/poly_test.o: include/pbc_param.h include/pbc_pairing.h
guru/poly_test.o: include/pbc_curve.h include/pbc_mnt.h
guru/poly_test.o: include/pbc_a1_param.h include/pbc_a_param.h
guru/poly_test.o: include/pbc_d_param.h include/pbc_e_param.h
guru/poly_test.o: include/pbc_f_param.h include/pbc_g_param.h
guru/poly_test.o: include/pbc_random.h include/pbc_memory.h include/pbc_fp.h
guru/poly_test.o: include/pbc_poly.h include/pbc_darray.h guru/test.h
guru/exp_test.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
guru/exp_test.o: include/pbc_param.h include/pbc_pairing.h
guru/exp_test.o: include/pbc_curve.h include/pbc_mnt.h include/pbc_a1_param.h
guru/exp_test.o: include/pbc_a_param.h include/pbc_d_param.h
guru/exp_test.o: include/pbc_e_param.h include/pbc_f_param.h
guru/exp_test.o: include/pbc_g_param.h include/pbc_random.h
guru/exp_test.o: include/pbc_memory.h include/pbc_time.h example/demo.h
guru/pairing_test.o: include/pbc.h include/pbc_utils.h include/pbc_field.h
guru/pairing_test.o: include/pbc_param.h include/pbc_pairing.h
guru/pairing_test.o: include/pbc_curve.h include/pbc_mnt.h
guru/pairing_test.o: include/pbc_a1_param.h include/pbc_a_param.h
guru/pairing_test.o: include/pbc_d_param.h include/pbc_e_param.h
guru/pairing_test.o: include/pbc_f_param.h include/pbc_g_param.h
guru/pairing_test.o: include/pbc_random.h include/pbc_memory.h guru/test.h
