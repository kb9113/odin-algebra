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

// evaluates the polynomial at x
eval :: proc{
    eval_same_type,
    eval_to_coefficient_type,
    eval_to_x_type,
}

eval_same_type :: proc(p : Polynomial($T, $ST), x : T) -> T
{
    assert(is_valid(p))

    if degree(p) == -1
    {
        when ST == field.NumericField(T)
        {
            return 0
        }
        else
        {
            ans : T
            p.algebraic_structure.set(&ans, p.algebraic_structure.add_identity)
            return ans
        }
    }

    ans := p.coefficients[degree(p)]

    for i := degree(p) - 1; i >= 0; i -= 1
    {
        when ST == field.NumericField(T)
        {
            ans *= x
            ans += p.coefficients[i]
        }
        else
        {
            p.algebraic_structure.mul(&ans, ans, x)
            p.algebraic_structure.add(&ans, ans, p.coefficients[i])
        }
    }
    return ans
}

// use this when you expect the output type to be the coefficient type
// s_mul should set ans = t * s
eval_to_coefficient_type :: proc(
    p : Polynomial($T, $ST),
    x : $V, s_mul : proc(ans : ^T, t : T, s : V)
) -> T where ST == field.NumericField(T) ||
    ST == euclidean_ring.NumericEuclideanRing(T) ||
    intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    assert(is_valid(p))

    if degree(p) == -1
    {
        when ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
        {
            return 0
        }
        else
        {
            ans : T
            p.algebraic_structure.set(&ans, p.algebraic_structure.add_identity)
            return ans
        }
    }

    ans : T
    p.algebraic_structure.set(&ans, p.coefficients[degree(p)])
    for i = (degree(p) - 1); i >= 0; i -= 1
    {
        s_mul(&ans, ans, x)
        when ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
        {
            ans += p.coefficients[i]
        }
        else
        {
            p.algebraic_structure.add(&ans, ans, p.coefficients[i])
        }
    }
    return ans
}

// use this when you expect the output type to be the type of x
// s_add should set ans = t + s
eval_to_x_type :: proc(
    p : Polynomial($T, $ST),
    x : $V, ring_x : $SV, s_add : proc(ans : ^V, t : T, s : V)
) -> V where (ST == field.NumericField(T) ||
        ST == euclidean_ring.NumericEuclideanRing(T) ||
        intrinsics.type_is_subtype_of(ST, ring.Ring(T))) &&
        (SV == field.NumericField(V) ||
        SV == euclidean_ring.NumericEuclideanRing(V) ||
        intrinsics.type_is_subtype_of(SV, ring.Ring(V)))
{
    assert(is_valid(p))

    if degree(p) == -1
    {
        when SV == field.NumericField(V) || SV == euclidean_ring.NumericEuclideanRing(V)
        {
            return 0
        }
        else
        {
            ans : V
            ring_x.set(&ans, ring_x.add_identity)
            return ans
        }
    }

    ans : V
    when SV == field.NumericField(V) || SV == euclidean_ring.NumericEuclideanRing(V)
    { s_add(&ans, p.coefficients[degree(p)], 0) }
    else { s_add(&ans, p.coefficients[degree(p)], ring_x.add_identity) }

    for i := degree(p) - 1; i >= 0; i -= 1
    {
        when SV == field.NumericField(V) || SV == euclidean_ring.NumericEuclideanRing(V)
        {
            ans *= x
            s_add(&ans, p.coefficients[i], ans)
        }
        else
        {
            ring_x.mul(&ans, ans, x)
            s_add(&ans, p.coefficients[i], ans)
        }
    }
    return ans
}

// s_add should set ans = t + s
muli_var_eval :: proc(
    p : Polynomial($T, $ST),
    x : [$N_VARS]$C, ring_x : $SC,
    s_add : proc(ans : ^C, t : $U, s : C)
) -> C
{
    x := x
    when N_VARS == 1
    {
        return eval_to_x_type(p, x[0], ring_x, s_add)
    }
    else
    {
        poly := make_uninitialized(C, ring_x, degree(p))
        defer delete_polynomial(poly)
        for i in 0..=degree(p)
        {
            new_x := (cast(^[N_VARS - 1]C)raw_data(x[1:]))^
            poly.coefficients[i] = muli_var_eval(
                p.coefficients[i],
                new_x, ring_x, s_add
            )
        }
        return eval(poly, x[0])
    }
}
