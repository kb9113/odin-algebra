package rational
import "../algebraic_structures/euclidean_ring"
import "../algebraic_structures/field"
import "../algebraic_structures/base"
import "core:log"
import "core:mem"
import "core:strings"
import "core:fmt"
import "base:intrinsics"

/*
This file contains the implementation of the base algebraic structure for rationals
*/

// makes an base structure for a rational given the numerator/denominator base structure
make_rational_base :: proc($T : typeid, coeffiencet_structure : $ST) -> base.Base(Rational(T, ST))
    where intrinsics.type_is_subtype_of(ST, base.Base(T))
{
    l_set :: proc(l : ^Rational(T, ST), r : Rational(T, ST))
    {
        set(l, r)
    }

    l_delete :: proc(l : Rational(T, ST))
    {
        delete_rational(l)
    }

    l_print :: proc(builder : ^strings.Builder, p : Rational(T, ST))
    {
        sb_print_rational(builder, p)
    }

    l_eq :: proc(l : Rational(T, ST), r : Rational(T, ST)) -> bool
    {
        return eq(l, r)
    }

    return base.Base(Rational(T, ST)){
        l_set,
        l_delete,
        l_eq,
        l_print,
    },
}

set :: proc{
    set_base,
    set_numeric,
}

set_base :: proc(l : ^Rational($T, $ST), r : Rational(T, ST))
    where intrinsics.type_is_subtype_of(ST, base.Base(T))
{
    using r.algebraic_structure
    set(&l.numerator, r.numerator)
    set(&l.denominator, r.denominator)
    l.algebraic_structure = r.algebraic_structure
}

set_numeric :: proc(l : ^Rational($T, $ST), r : Rational(T, ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    l.numerator = r.numerator
    l.denominator = r.denominator
    l.algebraic_structure = r.algebraic_structure
}

delete_rational :: proc{
    delete_rational_base,
    delete_rational_numeric,
}

delete_rational_base :: proc(r : Rational($T, $ST))
    where intrinsics.type_is_subtype_of(ST, base.Base(T))
{
    r.algebraic_structure.delete(r.numerator)
    r.algebraic_structure.delete(r.denominator)
}

delete_rational_numeric :: proc(r : Rational($T, $ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{

}

sb_print_rational :: proc{
    sb_print_rational_base,
    sb_print_rational_numeric,
}

sb_print_rational_base :: proc(builder : ^strings.Builder, r : Rational($T, $ST))
    where intrinsics.type_is_subtype_of(ST, base.Base(T))
{
    using r.algebraic_structure
    fmt.sbprint(builder, "(")
    print(builder, r.numerator)
    fmt.sbprint(builder, ")/(")
    print(builder, r.denominator)
    fmt.sbprint(builder, ")")
}

sb_print_rational_numeric :: proc(builder : ^strings.Builder, r : Rational($T, $ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    fmt.sbprint(builder, "(", r.numerator, ")/(", r.denominator, ")")
}

eq :: proc{
    eq_base,
    eq_numeric,
}

eq_base :: proc(l : Rational($T, $ST), r : Rational(T, ST)) -> bool
    where intrinsics.type_is_subtype_of(ST, base.Base(T))
{
    using l.algebraic_structure
    prod_1 : T
    defer delete(prod_1)
    mul(&prod_1, l.numerator, r.denominator)
    prod_2 : T
    defer delete(prod_2)
    mul(&prod_2, r.numerator, l.denominator)
    return eq(prod_1, prod_2)
}

eq_numeric :: proc(l : Rational($T, $ST), r : Rational(T, ST)) -> bool
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    using l.algebraic_structure
    return l.numerator * r.denominator == r.numerator * l.denominator
}
