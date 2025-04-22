package polynomial
import "core:math"
import "core:math/cmplx"
import "core:slice"
import "base:intrinsics"
import "core:log"
import "core:mem"
import "../algebraic_structures/ring"
import "../algebraic_structures/field"
import "../algebraic_structures/euclidean_ring"

differentiate :: proc{
    differentiate_numeric,
    differentiate_ring,
}

differentiate_ring :: proc(p : Polynomial($T, $ST)) -> Polynomial(T, ST)
    where intrinsics.type_is_subtype_of(ST, ring.CommutativeRing(T))
{
    assert(is_valid(p))

    if degree(p) == -1
    {
        return make_from_coefficients(T, p.algebraic_structure, []T{})
    }

    ans := make_uninitialized(T, p.algebraic_structure, degree(p) - 1)

    if degree(p) > 0 { p.algebraic_structure.set(&ans.coefficients[0], p.algebraic_structure.mul_identity) }
    for i in 1..<degree(p)
    {
        p.algebraic_structure.add(
            &ans.coefficients[i],
            ans.coefficients[i - 1],
            p.algebraic_structure.mul_identity
        )
    }

    for i in 1..=degree(p)
    {
        p.algebraic_structure.mul(
            &ans.coefficients[i - 1],
            ans.coefficients[i - 1],
            p.coefficients[i]
        )
    }

    return ans
}

differentiate_numeric :: proc(p : Polynomial($T, $ST)) -> Polynomial(T, ST)
    where ST == field.NumericField(T) || ST == euclidean_ring.EuclideanRing(T)
{
    assert(is_valid(p))

    if degree(p) == -1
    {
        return make_from_coefficients(T, p.algebraic_structure, []T{})
    }

    ans := make_uninitialized(T, p.algebraic_structure, degree(p) - 1)
    for i in 1..=degree(p)
    {
        ans.coefficients[i - 1] = T(i) * p.coefficients[i]
    }

    return ans
}

// polynomial must be over a field since we need to be able to divide to integrate
integrate :: proc{
    integrate_field,
    integrate_numeric,
}

integrate_field :: proc(p : Polynomial($T, $ST), c : T) -> Polynomial(T, ST)
    where intrinsics.type_is_subtype_of(ST, field.Field(T))
{
    assert(is_valid(p))

    ans := make_uninitialized(T, p.algebraic_structure, degree(p) + 1)

    p.algebraic_structure.set(&ans.coefficients[0], p.algebraic_structure.add_identity)
    for i in 1..=(degree(p) + 1)
    {
        p.algebraic_structure.add(
            &ans.coefficients[i],
            ans.coefficients[i - 1],
            p.algebraic_structure.mul_identity
        )
    }

    for i in 0..=degree(p)
    {
        p.algebraic_structure.div(
            &ans.coefficients[i + 1],
            p.coefficients[i],
            ans.coefficients[i + 1]
        )
    }
    p.algebraic_structure.set(&ans.coefficients[0], c)
    shrink_to_valid(&ans) // we only actually need to do this when c == 0
    return ans
}

integrate_numeric :: proc(p : Polynomial($T, $ST), c : T)
    where ST == field.NumericField(T)
{
    assert(is_valid(p))

    ans := make_uninitialized(T, p.algebraic_structure, degree(p) + 1)

    for i in 1..=(degree(p) + 1)
    {
        ans.coefficients[i] = p.coefficients[i - 1] / T(i)
    }

    ans.coefficients[0] = c
    shrink_to_valid(&ans) // we only actually need to do this when c == 0
    return ans
}
