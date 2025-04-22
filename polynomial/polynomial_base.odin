package polynomial
import "core:math"
import "core:math/cmplx"
import "core:slice"
import "base:intrinsics"
import "core:log"
import "core:mem"
import "core:fmt"
import "core:strings"
import "../algebraic_structures/base"
import "../algebraic_structures/field"
import "../algebraic_structures/euclidean_ring"

/*
This file contains the implementation of the base algebraic structure for polynomials
*/

// makes an base structure for a polynomial given the coefficents base structure
make_polynomial_base :: proc($T : typeid, coefficents_structure : $ST) ->
    base.Base(Polynomial(T, ST)) where intrinsics.type_is_subtype_of(ST, base.Base(T))
{
    l_set :: proc(l : ^Polynomial(T, ST), r : Polynomial(T, ST))
    {
        set(l, r)
    }

    l_delete :: proc(l : Polynomial(T, ST))
    {
        delete_polynomial(l)
    }

    l_print :: proc(builder : ^strings.Builder, p : Polynomial(T, ST))
    {
        sb_print_polynomial(builder, p)
    }

    l_eq :: proc(l : Polynomial(T, ST), r : Polynomial(T, ST)) -> bool
    {
        return eq(l, r)
    }

    return base.Base(Polynomial(T, ST)){
        l_set,
        l_delete,
        l_eq,
        l_print,
    },
}

// checks if 2 polynomials are equal
eq :: proc{
    eq_base,
    eq_numeric,
}

eq_base :: proc(p : Polynomial($T, $ST), q : Polynomial(T, ST)) -> bool
    where intrinsics.type_is_subtype_of(ST, base.Base(T))
{
    assert(is_valid(p))
    assert(is_valid(q))
    if degree(p) != degree(q)
    {
        return false
    }
    for i in 0..=degree(p)
    {
        if !p.algebraic_structure.eq(p.coefficents[i], q.coefficents[i]) { return false }
    }
    return true
}

eq_numeric :: proc(p : Polynomial($T, $ST), q : Polynomial(T, ST)) -> bool
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    assert(is_valid(p))
    assert(is_valid(q))

    if degree(p) != degree(q)
    {
        return false
    }
    for i in 0..=degree(p)
    {
        if p.coefficents[i] != q.coefficents[i] { return false }
    }
    return true
}

// sets l equal to a clone of r
set :: proc{
    set_base,
    set_numeric,
}

set_base :: proc(l : ^Polynomial($T, $ST), r : Polynomial(T, ST))
    where intrinsics.type_is_subtype_of(ST, base.Base(T))
{
    using l.algebraic_structure
    assert(is_valid(l^))
    assert(is_valid(r))

    resize_or_init_polynomial(l, r.algebraic_structure, degree(r))

    for i in 0..=degree(r)
    {
        l.algebraic_structure.set(&l.coefficents[i], r.coefficents[i])
    }
}

set_numeric :: proc(l : ^Polynomial($T, $ST), r : Polynomial(T, ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    assert(is_valid(l^))
    assert(is_valid(r))

    resize_or_init_polynomial(l, r.algebraic_structure, degree(r))

    for i in 0..=degree(r)
    {
        l.coefficents[i] = r.coefficents[i]
    }
}

// deletes a polynomial also deletes the coefficents using the underlying algebraic structure
delete_polynomial :: proc(p : Polynomial($T, $ST))
{
    when ST != field.NumericField(T)
    {
        for i in 0..=degree(p)
        {
            p.algebraic_structure.delete(p.coefficents[i])
        }
    }
    delete(p.coefficents)
}

// prints a polynomial to the input string builder
sb_print_polynomial :: proc{
    sb_print_polynomial_base,
    sb_print_polynomial_numeric,
}

sb_print_polynomial_base :: proc(builder : ^strings.Builder, p : Polynomial($T, $ST))
    where intrinsics.type_is_subtype_of(ST, base.Base(T))
{
    using p.algebraic_structure
    if degree(p) == -1
    {
        print(builder, add_identity)
    }
    for i := degree(p); i >= 0; i -= 1
    {
        if eq(p.coefficents[i], add_identity) { continue }
        if i != degree(p) { fmt.sbprint(builder, " + ", sep = "") }
        fmt.sbprint(builder, "(")
        print(builder, p.coefficents[i])
        fmt.sbprint(builder, ")")
        if i != 0 { fmt.sbprint(builder, "x^", i, sep = "") }
    }
}

sb_print_polynomial_numeric :: proc(builder : ^strings.Builder, p : Polynomial($T, $ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    if degree(p) == -1
    {
        fmt.sbprint(builder, 0)
    }
    for i := degree(p); i >= 0; i -= 1
    {
        if eq(p.coefficents[i], add_identity) { continue }
        if i != degree(p) { fmt.sbprint(builder, " + ", sep = "") }
        fmt.sbprint(builder, "(")
        fmt.sbprint(builder, p.coefficents[i])
        fmt.sbprint(builder, ")")
        if i != 0 { fmt.sbprint(builder, "x^", i, sep = "") }
    }
}

// logs a polynomial to context.logger in the standard way
log_polynomial :: proc(p : Polynomial($T, $ST))
{
    sb := strings.builder_make()
    sb_print_polynomial(&sb, p)
    log.info(strings.to_string(sb))
    strings.builder_destroy(&sb)
}

// prints a polynomial using fmt
print_polynomial :: proc(p : Polynomial($T, $ST))
{
    sb := strings.builder_make()
    sb_print_polynomial(&sb, p)
    fmt.println(strings.to_string(sb))
    strings.builder_destroy(&sb)
}
