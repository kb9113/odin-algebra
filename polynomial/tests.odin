package polynomial

import "core:testing"
import "core:log"
import "base:intrinsics"
import "base:builtin"
import "base:runtime"
import "core:slice"
import "core:math/cmplx"
import sa "core:container/small_array"
import "../prop_based"
import "../algebraic_structures/field"
import "../algebraic_structures/euclidean_ring"
import "../algebraic_structures/ring"
import "../algebraic_structures/integral_domain"
import "../algebraic_structures/base"
import "../rational"
import "core:fmt"
import "core:strings"
import "core:math/rand"

@(test)
test_polynomial_over_i64_integral_domain_axioms :: proc(t: ^testing.T)
{
    id := make_polynomial_integral_domain(i64, integral_domain.INTEGRAL_DOMAIN_I64)
    defer delete_polynomial_integral_domain(id)
    polynomial_generator := make_generator(prop_based.GENERATOR_I64, integral_domain.INTEGRAL_DOMAIN_I64)
    defer delete_generator(polynomial_generator)
    integral_domain.test_integral_domain_axioms(t, polynomial_generator, id)
}

@(test)
test_polynomial_over_i64_integral_domain_safety_axioms :: proc(t: ^testing.T)
{
    id := make_polynomial_integral_domain(i64, integral_domain.INTEGRAL_DOMAIN_I64)
    defer delete_polynomial_integral_domain(id)
    polynomial_generator := make_generator(prop_based.GENERATOR_I64, integral_domain.INTEGRAL_DOMAIN_I64)
    defer delete_generator(polynomial_generator)
    integral_domain.test_memory_safety_axioms(t, polynomial_generator, id)
}

@(test)
test_polynomial_over_polynomial_over_i64_integral_domain_axioms :: proc(t: ^testing.T)
{
    poly_id := make_polynomial_integral_domain(i64, integral_domain.INTEGRAL_DOMAIN_I64)
    defer delete_polynomial_integral_domain(poly_id)
    poly_generator := make_generator(prop_based.GENERATOR_I64, integral_domain.INTEGRAL_DOMAIN_I64)
    defer delete_generator(poly_generator)

    poly_poly_id := make_polynomial_integral_domain(Polynomial(i64, integral_domain.IntegralDomain(i64)), poly_id)
    defer delete_polynomial_integral_domain(poly_poly_id)
    poly_poly_generator := make_generator(poly_generator, poly_id)
    defer delete_generator(poly_poly_generator)

    integral_domain.test_integral_domain_axioms(t, poly_poly_generator, poly_poly_id)
}

@(test)
test_polynomial_over_polynomial_over_i64_integral_safety_axioms :: proc(t: ^testing.T)
{
    poly_id := make_polynomial_integral_domain(i64, integral_domain.INTEGRAL_DOMAIN_I64)
    defer delete_polynomial_integral_domain(poly_id)
    poly_generator := make_generator(prop_based.GENERATOR_I64, integral_domain.INTEGRAL_DOMAIN_I64)
    defer delete_generator(poly_generator)

    poly_poly_id := make_polynomial_integral_domain(Polynomial(i64, integral_domain.IntegralDomain(i64)), poly_id)
    defer delete_polynomial_integral_domain(poly_poly_id)
    poly_poly_generator := make_generator(poly_generator, poly_id)
    defer delete_generator(poly_poly_generator)

    integral_domain.test_memory_safety_axioms(t, poly_poly_generator, poly_poly_id)
}

@(test)
test_calc_prop_based :: proc(t: ^testing.T)
{
    integrate_then_differentiate :: proc(f : integral_domain.IntegralDomain(Polynomial(f32, field.Field(f32))), a : Polynomial(f32, field.Field(f32))) -> bool
    {
        int := integrate(a, a.algebraic_structure.add_identity)
        defer delete_polynomial(int)

        base.log_base_object(f.commutative_ring.ring.base, "integrate(a, 0) =", int)

        diff := differentiate(int)
        defer delete_polynomial(diff)

        base.log_base_object(f.commutative_ring.ring.base, "differentiate(integrate(a, 0)) =", diff)

        return f.eq(diff, a)
    }

    differentiate_then_integrate :: proc(f : integral_domain.IntegralDomain(Polynomial(f32, field.Field(f32))), a : Polynomial(f32, field.Field(f32))) -> bool
    {
        if degree(a) == -1
        {
            return true
        }

        c := a.coefficients[0]

        diff := differentiate(a)
        defer delete_polynomial(diff)

        base.log_base_object(f.commutative_ring.ring.base, "differentiate(a) =", diff)

        int := integrate(diff, c)
        defer delete_polynomial(int)

        base.log_base_object(f.commutative_ring.ring.base, "integrate(differentiate(a), c) =", int)

        return f.eq(int, a)
    }

    poly_id := make_polynomial_integral_domain(f32, field.FIELD_F32)
    defer delete_polynomial_integral_domain(poly_id)
    poly_generator := make_generator(prop_based.GENERATOR_F32, field.FIELD_F32)
    defer delete_generator(poly_generator)

    prop_based.check(
        t,
        poly_id, poly_generator, integrate_then_differentiate
    )

    prop_based.check(
        t,
        poly_id, poly_generator, differentiate_then_integrate
    )
}

@(test)
test_eq_1 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, []f32{1, 2, 3})
    p2 := make_from_coefficients(f32, []f32{1, 2, 3})
    testing.expect(
        t, eq(p1, p2)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
}

@(test)
test_eq_2 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, []f32{1, 2, 4})
    p2 := make_from_coefficients(f32, []f32{1, 2, 3})
    testing.expect(
        t, !eq(p1, p2)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
}

@(test)
test_eq_3 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, []f32{1, 2, 3})
    p2 := make_from_coefficients(f32, []f32{1, 2, 3})
    testing.expect(
        t, eq(p1, p2)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
}

@(test)
test_eq_4 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, []f32{})
    p2 := make_from_coefficients(f32, []f32{})
    testing.expect(
        t, eq(p1, p2)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
}

@(test)
test_add_1 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, []f32{1, 2, 3})
    p2 := make_from_coefficients(f32, []f32{2, 3, 4})
    sum := make_uninitialized(f32, -1)
    add(&sum, p1, p2)
    expected_sum := make_from_coefficients(f32, []f32{3, 5, 7})
    testing.expect(
        t, eq(sum, expected_sum)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
    delete_polynomial(sum)
    delete_polynomial(expected_sum)
}

@(test)
test_add_2 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, field.FIELD_F32, []f32{1, 2, 3})
    p2 := make_from_coefficients(f32, field.FIELD_F32, []f32{2, 3, 4})
    sum := make_uninitialized(f32, field.FIELD_F32, -1)
    add(&sum, p1, p2)
    expected_sum := make_from_coefficients(f32, field.FIELD_F32, []f32{3, 5, 7})
    testing.expect(
        t, eq(sum, expected_sum)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
    delete_polynomial(sum)
    delete_polynomial(expected_sum)
}

@(test)
test_add_3 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, []f32{1, 2, 3})
    p2 := make_from_coefficients(f32, []f32{2, 3, 4})
    add(&p1, p1, p2)
    expected_sum := make_from_coefficients(f32, []f32{3, 5, 7})
    testing.expect(
        t, eq(p1, expected_sum)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
    delete_polynomial(expected_sum)
}

@(test)
test_add_4 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, field.FIELD_F32, []f32{1, 2, 3})
    p2 := make_from_coefficients(f32, field.FIELD_F32, []f32{2, 3, 4})
    add(&p1, p1, p2)
    expected_sum := make_from_coefficients(f32, field.FIELD_F32, []f32{3, 5, 7})
    testing.expect(
        t, eq(p1, expected_sum)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
    delete_polynomial(expected_sum)
}

@(test)
test_ref_add_3 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, field.FIELD_F32, []f32{1, 2, 3})
    add(&p1, p1, p1)
    expected_sum := make_from_coefficients(f32, field.FIELD_F32, []f32{2, 4, 6})
    testing.expect(
        t, eq(p1, expected_sum)
    )
    delete_polynomial(p1)
    delete_polynomial(expected_sum)
}

@(test)
test_sub_1 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, []f32{1, 2, 3})
    p2 := make_from_coefficients(f32, []f32{2, 3, 4})
    dif := make_uninitialized(f32, -1)
    sub(&dif, p1, p2)
    expected_sub := make_from_coefficients(f32, []f32{-1, -1, -1})
    testing.expect(
        t, eq(dif, expected_sub)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
    delete_polynomial(dif)
    delete_polynomial(expected_sub)
}

@(test)
test_sub_2 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, field.FIELD_F32, []f32{1, 2, 3})
    p2 := make_from_coefficients(f32, field.FIELD_F32, []f32{2, 3, 4})
    dif := make_uninitialized(f32, field.FIELD_F32, -1)
    sub(&dif, p1, p2)
    expected_sub := make_from_coefficients(f32, field.FIELD_F32, []f32{-1, -1, -1})
    testing.expect(
        t, eq(dif, expected_sub)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
    delete_polynomial(dif)
    delete_polynomial(expected_sub)
}

@(test)
test_sub_3 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, []f32{1, 2, 3})
    p2 := make_from_coefficients(f32, []f32{2, 3, 4})
    sub(&p1, p1, p2)
    expected_sub := make_from_coefficients(f32, []f32{-1, -1, -1})
    testing.expect(
        t, eq(p1, expected_sub)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
    delete_polynomial(expected_sub)
}

@(test)
test_ref_sub_2 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, field.FIELD_F32, []f32{1, 2, 3})
    p2 := make_from_coefficients(f32, field.FIELD_F32, []f32{2, 3, 4})
    sub(&p1, p1, p2)
    expected_sub := make_from_coefficients(f32, field.FIELD_F32, []f32{-1, -1, -1})
    testing.expect(
        t, eq(p1, expected_sub)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
    delete_polynomial(expected_sub)
}

@(test)
test_ref_sub_3 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, field.FIELD_F32, []f32{1, 2, 3})
    sub(&p1, p1, p1)
    expected_sum := make_from_coefficients(f32, field.FIELD_F32, []f32{})
    testing.expect(
        t, eq(p1, expected_sum)
    )
    delete_polynomial(p1)
    delete_polynomial(expected_sum)
}

@(test)
test_mul_1 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, []f32{1, 2, 3})
    p2 := make_from_coefficients(f32, []f32{2, 3, 4})
    prod := make_uninitialized(f32, -1)
    mul(&prod, p1, p2)
    expected_prod := make_from_coefficients(f32, []f32{2, 7, 16, 17, 12})
    testing.expect(
        t, eq(prod, expected_prod)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
    delete_polynomial(prod)
    delete_polynomial(expected_prod)
}

@(test)
test_mul_2 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, field.FIELD_F32, []f32{1, 2, 3})
    p2 := make_from_coefficients(f32, field.FIELD_F32, []f32{2, 3, 4})
    prod := make_uninitialized(f32, field.FIELD_F32, -1)
    mul(&prod, p1, p2)
    expected_prod := make_from_coefficients(f32, field.FIELD_F32, []f32{2, 7, 16, 17, 12})
    testing.expect(
        t, eq(prod, expected_prod)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
    delete_polynomial(prod)
    delete_polynomial(expected_prod)
}

@(test)
test_mul_3 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, []f32{1, 2, 3})
    p2 := make_from_coefficients(f32, []f32{2, 3, 4})
    mul(&p1, p1, p2)
    expected_prod := make_from_coefficients(f32, []f32{2, 7, 16, 17, 12})
    testing.expect(
        t, eq(p1, expected_prod)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
    delete_polynomial(expected_prod)
}

@(test)
test_mul_4 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, field.FIELD_F32, []f32{1, 2, 3})
    p2 := make_from_coefficients(f32, field.FIELD_F32, []f32{2, 3, 4})
    mul(&p1, p1, p2)
    expected_prod := make_from_coefficients(f32, field.FIELD_F32, []f32{2, 7, 16, 17, 12})
    testing.expect(
        t, eq(p1, expected_prod)
    )
    delete_polynomial(p1)
    delete_polynomial(p2)
    delete_polynomial(expected_prod)
}

@(test)
test_mul_5 :: proc(t: ^testing.T)
{
    p1 := make_from_coefficients(f32, field.FIELD_F32, []f32{1, 2, 3})
    mul(&p1, p1, p1)

    expected_sum := make_from_coefficients(f32, field.FIELD_F32, []f32{1, 4, 10, 12, 9})
    testing.expect(
        t, eq(p1, expected_sum)
    )
    delete_polynomial(p1)
    delete_polynomial(expected_sum)
}

@(test)
test_mul_6 :: proc(t: ^testing.T)
{
    id := make_polynomial_integral_domain(i64, integral_domain.INTEGRAL_DOMAIN_I64)
    defer delete_polynomial_integral_domain(id)

    //x^2+x+1
    p := make_from_coefficients(
        Polynomial(i64, integral_domain.IntegralDomain(i64)),
        id,
        []Polynomial(i64, integral_domain.IntegralDomain(i64)){
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{1}),
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{1}),
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{1}),
        }
    )

    // x^2-1+y
    q := make_from_coefficients(
        Polynomial(i64, integral_domain.IntegralDomain(i64)),
        id,
        []Polynomial(i64, integral_domain.IntegralDomain(i64)){
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{-1, 1}),
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{}),
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{1}),
        }
    )

    prod : Polynomial(Polynomial(i64, integral_domain.IntegralDomain(i64)), integral_domain.IntegralDomain(Polynomial(i64, integral_domain.IntegralDomain(i64))))
    mul(&prod, p, q)

    expected_prod := make_from_coefficients(
        Polynomial(i64, integral_domain.IntegralDomain(i64)),
        id,
        []Polynomial(i64, integral_domain.IntegralDomain(i64)){
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{-1, 1}),
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{-1, 1}),
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{0, 1}),
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{1}),
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{1}),
        }
    )
    testing.expect(
        t, eq(prod, expected_prod)
    )

    delete_polynomial(p)
    delete_polynomial(q)
    delete_polynomial(prod)
    delete_polynomial(expected_prod)
}

@(test)
test_div_1 :: proc(t: ^testing.T)
{
    p := make_from_coefficients(f32, []f32{-10, -3, 1})
    q := make_from_coefficients(f32, []f32{2, 1})
    quot, rem : Polynomial(f32, field.NumericField(f32))
    div(&quot, &rem, p, q)


    expected_div := make_from_coefficients(f32, []f32{-5, 1})
    expected_rem := make_from_coefficients(f32, []f32{})
    testing.expect(t, eq(quot, expected_div))
    testing.expect(t, eq(rem, expected_rem))

    delete_polynomial(p)
    delete_polynomial(q)
    delete_polynomial(quot)
    delete_polynomial(rem)
    delete_polynomial(expected_div)
    delete_polynomial(expected_rem)
}

@(test)
test_div_2 :: proc(t: ^testing.T)
{
    p := make_from_coefficients(f32, []f32{-1, -5, 2})
    q := make_from_coefficients(f32, []f32{-3, 1})
    quot, rem : Polynomial(f32, field.NumericField(f32))
    div(&quot, &rem, p, q)

    expected_div := make_from_coefficients(f32, []f32{1, 2})
    expected_rem := make_from_coefficients(f32, []f32{2})
    testing.expect(t, eq(quot, expected_div))
    testing.expect(t, eq(rem, expected_rem))

    delete_polynomial(p)
    delete_polynomial(q)
    delete_polynomial(quot)
    delete_polynomial(rem)
    delete_polynomial(expected_div)
    delete_polynomial(expected_rem)
}

@(test)
test_div_3 :: proc(t: ^testing.T)
{
    p := make_from_coefficients(f32, []f32{-9, 6, 0, 0, 2, 0, 1})
    q := make_from_coefficients(f32, []f32{3, 0, 0, 1})
    quot, rem : Polynomial(f32, field.NumericField(f32))
    div(&quot, &rem, p, q)

    expected_div := make_from_coefficients(f32, []f32{-3, 2, 0, 1})
    expected_rem := make_from_coefficients(f32, []f32{})
    testing.expect(t, eq(quot, expected_div))
    testing.expect(t, eq(rem, expected_rem))

    delete_polynomial(p)
    delete_polynomial(q)
    delete_polynomial(quot)
    delete_polynomial(rem)
    delete_polynomial(expected_div)
    delete_polynomial(expected_rem)
}

@(test)
test_div_4 :: proc(t: ^testing.T)
{
    p := make_from_coefficients(f32, []f32{9})
    q := make_from_coefficients(f32, []f32{4})
    quot, rem : Polynomial(f32, field.NumericField(f32))
    div(&quot, &rem, p, q)

    expected_div := make_from_coefficients(f32, []f32{2.25})
    expected_rem := make_from_coefficients(f32, []f32{})
    testing.expect(t, eq(quot, expected_div))
    testing.expect(t, eq(rem, expected_rem))

    delete_polynomial(p)
    delete_polynomial(q)
    delete_polynomial(quot)
    delete_polynomial(rem)
    delete_polynomial(expected_div)
    delete_polynomial(expected_rem)
}

@(test)
test_div_5 :: proc(t: ^testing.T)
{
    p := make_from_coefficients(f32, field.FIELD_F32, []f32{-10, -3, 1})
    q := make_from_coefficients(f32, field.FIELD_F32, []f32{2, 1})
    quot, rem : Polynomial(f32, field.Field(f32))
    div(&quot, &rem, p, q)

    expected_div := make_from_coefficients(f32, field.FIELD_F32, []f32{-5, 1})
    expected_rem := make_from_coefficients(f32, field.FIELD_F32, []f32{})
    testing.expect(t, eq(quot, expected_div))
    testing.expect(t, eq(rem, expected_rem))

    delete_polynomial(p)
    delete_polynomial(q)
    delete_polynomial(quot)
    delete_polynomial(rem)
    delete_polynomial(expected_div)
    delete_polynomial(expected_rem)
}

@(test)
test_div_6 :: proc(t: ^testing.T)
{
    p := make_from_coefficients(f32, field.FIELD_F32, []f32{-1, -5, 2})
    q := make_from_coefficients(f32, field.FIELD_F32, []f32{-3, 1})
    quot, rem : Polynomial(f32, field.Field(f32))
    div(&quot, &rem, p, q)

    expected_div := make_from_coefficients(f32, field.FIELD_F32, []f32{1, 2})
    expected_rem := make_from_coefficients(f32, field.FIELD_F32, []f32{2})
    testing.expect(t, eq(quot, expected_div))
    testing.expect(t, eq(rem, expected_rem))

    delete_polynomial(p)
    delete_polynomial(q)
    delete_polynomial(quot)
    delete_polynomial(rem)
    delete_polynomial(expected_div)
    delete_polynomial(expected_rem)
}

@(test)
test_div_7 :: proc(t: ^testing.T)
{
    p := make_from_coefficients(f32, field.FIELD_F32, []f32{-9, 6, 0, 0, 2, 0, 1})
    q := make_from_coefficients(f32, field.FIELD_F32, []f32{3, 0, 0, 1})
    quot, rem : Polynomial(f32, field.Field(f32))
    div(&quot, &rem, p, q)

    expected_div := make_from_coefficients(f32, field.FIELD_F32, []f32{-3, 2, 0, 1})
    expected_rem := make_from_coefficients(f32, field.FIELD_F32, []f32{})
    testing.expect(t, eq(quot, expected_div))
    testing.expect(t, eq(rem, expected_rem))

    delete_polynomial(p)
    delete_polynomial(q)
    delete_polynomial(quot)
    delete_polynomial(rem)
    delete_polynomial(expected_div)
    delete_polynomial(expected_rem)
}

@(test)
test_div_8 :: proc(t: ^testing.T)
{
    p := make_from_coefficients(f32, field.FIELD_F32, []f32{9})
    q := make_from_coefficients(f32, field.FIELD_F32, []f32{4})
    quot, rem : Polynomial(f32, field.Field(f32))
    div(&quot, &rem, p, q)

    expected_div := make_from_coefficients(f32, field.FIELD_F32, []f32{2.25})
    expected_rem := make_from_coefficients(f32, field.FIELD_F32, []f32{})
    testing.expect(t, eq(quot, expected_div))
    testing.expect(t, eq(rem, expected_rem))

    delete_polynomial(p)
    delete_polynomial(q)
    delete_polynomial(quot)
    delete_polynomial(rem)
    delete_polynomial(expected_div)
    delete_polynomial(expected_rem)
}

@(test)
test_cancel_1 :: proc(t : ^testing.T)
{
    p := make_from_coefficients(i32, integral_domain.INTEGRAL_DOMAIN_I32, []i32{1, 2, 3})
    q := make_from_coefficients(i32, integral_domain.INTEGRAL_DOMAIN_I32, []i32{-2, 3})
    pq := make_from_coefficients(i32, integral_domain.INTEGRAL_DOMAIN_I32, []i32{})
    mul(&pq, p, q)
    p_canceled := make_from_coefficients(i32, integral_domain.INTEGRAL_DOMAIN_I32, []i32{})
    cancel(&p_canceled, pq, q)

    testing.expect(t, eq(p_canceled, p))

    delete_polynomial(p)
    delete_polynomial(q)
    delete_polynomial(pq)
    delete_polynomial(p_canceled)
}

@(test)
test_differentiate_1 :: proc(t: ^testing.T)
{
    p := make_from_coefficients(f32, []f32{1, 2, 3, 4})
    dp := differentiate(p)
    expected_dp := make_from_coefficients(f32, []f32{2, 6, 12})
    testing.expect(
        t, eq(dp, expected_dp)
    )

    delete_polynomial(p)
    delete_polynomial(dp)
    delete_polynomial(expected_dp)
}

@(test)
test_differentiate_2 :: proc(t: ^testing.T)
{
    p := make_from_coefficients(f32, field.FIELD_F32, []f32{1, 2, 3, 4})
    dp := differentiate(p)
    expected_dp := make_from_coefficients(f32, field.FIELD_F32, []f32{2, 6, 12})
    testing.expect(
        t, eq(dp, expected_dp)
    )

    delete_polynomial(p)
    delete_polynomial(dp)
    delete_polynomial(expected_dp)
}

@(test)
test_eval_1 :: proc(t: ^testing.T)
{
    p := make_from_coefficients(f32, []f32{1, 2, 3})
    f_1 := eval(p, f32(1))
    testing.expectf(
        t, f_1 == 6, "expected f(1) == 6 but got f(1) == %f", f_1
    )
    delete_polynomial(p)
}

@(test)
test_eval_2 :: proc(t: ^testing.T)
{
    p := make_from_coefficients(f32, field.FIELD_F32, []f32{1, 2, 3})
    f_1 := eval(p, f32(1))
    testing.expectf(
        t, f_1 == 6, "expected f(1) == 6 but got f(1) == %f", f_1
    )
    delete_polynomial(p)
}

@(test)
test_roots :: proc(t: ^testing.T)
{
    s_add :: proc(ans : ^complex64, t : f32, s : complex64)
    {
        ans^ = s + complex64(t)
    }

    p := make_from_coefficients(f32, []f32{-1, -2, 3, 4})
    rs := roots(p)

    testing.expect(t, len(rs) == 3)
    for r in rs
    {
        root_value := eval(p, r, field.NumericField(complex64){}, s_add)
        testing.expect(t, abs(root_value) < 1e-6)
    }
    delete(rs)
    delete_polynomial(p)
}

@(test)
test_real_roots :: proc(t: ^testing.T)
{
    p := make_from_coefficients(f32, []f32{-1, -2, 3, 4})
    rs := real_roots(p)

    testing.expect(t, len(rs) == 3)
    for r in rs
    {
        root_value := eval(p, r)
        testing.expect(t, abs(root_value) < 1e-6)
    }
    delete(rs)
    delete_polynomial(p)
}

@(test)
test_sub_resultant_pseudo_remainder_seq :: proc(t: ^testing.T)
{
    p := make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{-5, 2, 8, -3, -3, 0, 1, 0, 1})
    q := make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{21, -9, -4, 0, 5, 0, 3})

    expected_sr_1 := make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{9, 0, -3, 0, 15})
    expected_sr_2 := make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{-245, 125, 65})
    expected_sr_3 := make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{-12300, 9326})
    expected_sr_4 := make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{260708})
    expected_sr_5 := make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{})

    it := make_sub_resultant_pseudo_remainder_iterator(p, q)

    sr1 := next_sub_resultant(&it)
    testing.expect(t, eq(sr1, expected_sr_1))

    sr2 := next_sub_resultant(&it)
    testing.expect(t, eq(sr2, expected_sr_2))

    sr3 := next_sub_resultant(&it)
    testing.expect(t, eq(sr3, expected_sr_3))

    sr4 := next_sub_resultant(&it)
    testing.expect(t, eq(sr4, expected_sr_4))

    sr5 := next_sub_resultant(&it)
    testing.expect(t, eq(sr5, expected_sr_5))

    delete_sub_resultant_pseudo_remainder_iterator(it)

    delete_polynomial(p)
    delete_polynomial(q)
    delete_polynomial(expected_sr_1)
    delete_polynomial(expected_sr_2)
    delete_polynomial(expected_sr_3)
    delete_polynomial(expected_sr_4)
    delete_polynomial(expected_sr_5)
}

@(test)
test_resultant_1 :: proc(t: ^testing.T)
{
    p := make_from_coefficients(i32, integral_domain.INTEGRAL_DOMAIN_I32, []i32{0, -2, 1})
    q := make_from_coefficients(i32, integral_domain.INTEGRAL_DOMAIN_I32, []i32{1, 2, 1})
    res := resultant(p, q)
    testing.expect(t, res == 9)

    delete_polynomial(p)
    delete_polynomial(q)
}

@(test)
test_resultant_2 :: proc(t: ^testing.T)
{
    p := make_from_coefficients(i32, integral_domain.INTEGRAL_DOMAIN_I32, []i32{1, 1, 1})
    q := make_from_coefficients(i32, integral_domain.INTEGRAL_DOMAIN_I32, []i32{1, 1, 0, 0, 0, 0, 0, -1})
    res := resultant(p, q)
    testing.expect(t, res == 1)

    delete_polynomial(p)
    delete_polynomial(q)
}

@(test)
test_resultant_3 :: proc(t: ^testing.T)
{
    p := make_from_coefficients(i32, integral_domain.INTEGRAL_DOMAIN_I32, []i32{0, -2, 1})
    q := make_from_coefficients(i32, integral_domain.INTEGRAL_DOMAIN_I32, []i32{0, 2, 1})
    res := resultant(p, q)
    testing.expect(t, res == 0)

    delete_polynomial(p)
    delete_polynomial(q)
}

@(test)
test_resultant_4 :: proc(t: ^testing.T)
{
    id := make_polynomial_integral_domain(i64, integral_domain.INTEGRAL_DOMAIN_I64)
    defer delete_polynomial_integral_domain(id)

    //x^2+x+1
    r1 := make_from_coefficients(
        Polynomial(i64, integral_domain.IntegralDomain(i64)),
        id,
        []Polynomial(i64, integral_domain.IntegralDomain(i64)){
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{1}),
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{1}),
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{1}),
        }
    )

    // x^2+1+y
    r2 := make_from_coefficients(
        Polynomial(i64, integral_domain.IntegralDomain(i64)),
        id,
        []Polynomial(i64, integral_domain.IntegralDomain(i64)){
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{-1, 1}),
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{}),
            make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{1}),
        }
    )

    res := resultant(r1, r2)
    expected_res := make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{3, -3, 1})

    testing.expect(t, eq(res, expected_res))

    delete_polynomial(r1)
    delete_polynomial(r2)
    delete_polynomial(expected_res)
    delete_polynomial(res)
}

@(test)
test_polynomial_pow :: proc(t: ^testing.T)
{
    id := make_polynomial_integral_domain(i64, integral_domain.INTEGRAL_DOMAIN_I64)
    defer delete_polynomial_integral_domain(id)

    p := make_from_coefficients(i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{1, 2, 3})
    defer delete_polynomial(p)
    p_n : Polynomial(i64, integral_domain.IntegralDomain(i64))
    ring.integer_pow(&p_n, p, 5, id)
    defer delete_polynomial(p_n)

    expected_p_n := make_from_coefficients(
        i64, integral_domain.INTEGRAL_DOMAIN_I64, []i64{1, 10, 55, 200, 530, 1052, 1590, 1800, 1485, 810, 243}
    )
    defer delete_polynomial(expected_p_n)

    testing.expect(
        t, eq(p_n, expected_p_n)
    )
}

@(test)
test_solve_system :: proc(t: ^testing.T)
{
    id := make_polynomial_integral_domain(f32, field.FIELD_F32)
    defer delete_polynomial_integral_domain(id)

    VAR1TYPE :: Polynomial(f32, field.Field(f32))
    system : [2]Polynomial(VAR1TYPE, integral_domain.IntegralDomain(VAR1TYPE))

    //x^2-10x-y^2
    system[0] = make_from_coefficients(
        Polynomial(f32, field.Field(f32)),
        id,
        []Polynomial(f32, field.Field(f32)){
            make_from_coefficients(f32, field.FIELD_F32, []f32{0, 0, -1}),
            make_from_coefficients(f32, field.FIELD_F32, []f32{-10}),
            make_from_coefficients(f32, field.FIELD_F32, []f32{1}),
        }
    )
    defer delete_polynomial(system[0])

    // x^2+1+y
    system[1] = make_from_coefficients(
        Polynomial(f32, field.Field(f32)),
        id,
        []Polynomial(f32, field.Field(f32)){
            make_from_coefficients(f32, field.FIELD_F32, []f32{1, 1}),
            make_from_coefficients(f32, field.FIELD_F32, []f32{}),
            make_from_coefficients(f32, field.FIELD_F32, []f32{1}),
        }
    )
    defer delete_polynomial(system[1])

    roots := solve_system(2, complex64, system)
    defer delete(roots)

    testing.expect(t, len(roots) == 4)
    for root in roots
    {
        s_add :: proc(ans : ^complex64, t : f32, s : complex64)
        {
            ans^ = complex64(t) + s
        }
        value_at_root_0 := muli_var_eval(
            system[0],
            root, field.NumericField(complex64){}, s_add
        )
        value_at_root_1 := muli_var_eval(
            system[0],
            root, field.NumericField(complex64){}, s_add
        )
        testing.expect(t, cmplx.abs(value_at_root_0) < 1e-6)
        testing.expect(t, cmplx.abs(value_at_root_1) < 1e-6)
    }
}
