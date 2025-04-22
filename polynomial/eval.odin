package polynomial
import "core:math"
import "core:math/cmplx"
import "core:slice"
import "base:intrinsics"
import "core:log"
import "core:mem"
import "../algebraic_structures/ring"
import "../algebraic_structures/field"

// evaluates the polynomial at x
eval :: proc{
    eval_same_type,
    eval_different_type,
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

// use this when the expected output type of your function is different to the coefficients type
eval_different_type :: proc(p : Polynomial($T, $ST), x : $V, s_mul : proc(s : V, t : T) -> V) ->
    V where intrinsics.type_is_numeric(V)
{
    assert(is_valid(p))

    ans : V = 0
    x_n : V = 1
    for i in 0..=degree(p)
    {
        ans += s_mul(x_n, p.coefficients[i])
        x_n *= x
    }
    return ans
}

// uses the durand–kerner method to return the complex roots
roots :: proc{
    roots_complex128,
    roots_complex64,
    roots_complex32,
}

roots_numeric :: proc($C : typeid, p : Polynomial($T, $ST), max_iterations := 100) -> []C
{
    assert(is_valid(p))

    s_mul :: proc(s : C, t : T) -> C
    {
        return s * C(t)
    }

    degree := degree(p)

    // init guesses
    roots := make([dynamic]C)
    curr : C = complex(0.3, 0.7)
    for i in 0..<degree
    {
        append(&roots, curr)
        curr *= complex(0.3, 0.7)
    }

    // find roots
    cumulative_change : T = 1
    i := 0
    for cumulative_change > 1e-6 && i < max_iterations
    {
        cumulative_change = 0
        for i in 0..<len(roots)
        {
            denominator : C = complex(1, 0)
            for j in 0..<len(roots)
            {
                if i == j { continue }
                denominator *= roots[i] - roots[j]
            }
            f_x := eval(p, roots[i], s_mul) / C(p.coefficients[degree])
            roots[i] -= f_x / denominator
            cumulative_change += cmplx.abs(f_x / denominator)
        }
        i += 1
    }
    return roots[:]
}

roots_complex128 :: proc(p : Polynomial($T, $ST)) -> []complex128
    where T == f64 || T == complex128
{
    return roots_numeric(complex128, p)
}

roots_complex64 :: proc(p : Polynomial($T, $ST)) -> []complex64
    where T == f32 || T == complex64
{
    return roots_numeric(complex64, p)
}

roots_complex32 :: proc(p : Polynomial($T, $ST)) -> []complex32
    where T == f16 || T == complex32
{
    return roots_numeric(complex32, p)
}


// uses the durand–kerner method to return the complex roots then filters the roots to only roots with small imaginary components
real_roots :: proc(p : Polynomial($T, $ST)) -> []T
    where intrinsics.type_is_float(T)
{
    complex_roots := roots(p)
    real_roots := make([dynamic]T)
    for root in complex_roots
    {
        if cmplx.imag(root) < 1e-6
        {
            append(&real_roots, cmplx.real(root))
        }
    }
    delete(complex_roots)
    return real_roots[:]
}
