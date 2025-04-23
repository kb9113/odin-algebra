package polynomial
import "core:math"
import "core:math/cmplx"
import "core:slice"
import "base:intrinsics"
import "core:log"
import "core:mem"
import "../algebraic_structures/ring"
import "../algebraic_structures/field"

// uses the durand–kerner method to return the complex roots
roots :: proc{
    roots_complex128,
    roots_complex64,
    roots_complex32,
}

roots_numeric :: proc($C : typeid, p : Polynomial($T, $ST), max_iterations := 100) -> []C
{
    assert(is_valid(p))

    s_add :: proc(ans : ^C, t : T, s : C)
    {
        ans^ = s + C(t)
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
    cumulative_change : intrinsics.type_elem_type(T) = 1
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
            f_x := eval_to_x_type(p, roots[i], field.NumericField(C){}, s_add) / C(p.coefficients[degree])
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

prepend_fixed_length :: proc($N : int, t : $T, ts : [N - 1]T) -> [N]T
{
    ans : [N]T
    ans[0] = t
    for i in 0..<(N - 1)
    {
        ans[i + 1] = ts[i]
    }
    return ans
}

roots_match :: proc(r1 : [$N]$C, r2 : [N]C) -> bool
{
    difference_sum : intrinsics.type_elem_type(C) = 0
    for i in 0..<N
    {
        difference_sum += cmplx.abs(r1[i] - r2[i])
    }
    return (difference_sum / intrinsics.type_elem_type(C)(N)) < 1e-6
}

// solves a multi variable system of equations expects the number of equations to match the number of variables
solve_system :: proc($N_VARS : int, $C : typeid, polynomials : [N_VARS]Polynomial($T, $ST)) -> [][N_VARS]C
{
    when N_VARS == 1
    {
        #assert(intrinsics.type_is_float(T))
        roots := roots(polynomials[0])
        defer delete(roots)
        ans := make([][N_VARS]C, len(roots))
        for i in 0..<len(roots)
        {
            ans[i] = [N_VARS]C{roots[i]}
        }
        return ans
    }
    else
    {
        polynomials_with_one_less_variable : [N_VARS - 1]T
        for i in 0..<(N_VARS - 1)
        {
            polynomials_with_one_less_variable[i] = resultant(polynomials[i], polynomials[i + 1])
        }
        sub_roots := solve_system(N_VARS - 1, C, polynomials_with_one_less_variable)
        defer delete(sub_roots)
        for i in 0..<(N_VARS - 1)
        {
            delete_polynomial(polynomials_with_one_less_variable[i])
        }

        polynomial_index_to_roots : [N_VARS][dynamic][N_VARS]C
        for sub_root in sub_roots
        {
            for i in 0..<N_VARS
            {
                // back substitute
                s_add :: proc(ans : ^complex64, t : f32, s : complex64)
                {
                    ans^ = complex64(t) + s
                }
                polynomials_in_one_variable := make_uninitialized(
                    C, field.NumericField(C){}, degree(polynomials[i])
                )
                defer delete_polynomial(polynomials_in_one_variable)
                for k in 0..=degree(polynomials[i])
                {
                    polynomials_in_one_variable.coefficients[k] = muli_var_eval(
                        polynomials[i].coefficients[k],
                        sub_root, field.NumericField(C){}, s_add
                    )
                }

                // append roots
                last_var_roots := roots(polynomials_in_one_variable)
                defer delete(last_var_roots)
                for last_var_root in last_var_roots
                {
                    append(&polynomial_index_to_roots[i],
                        prepend_fixed_length(N_VARS, last_var_root, sub_root)
                    )
                }
            }
        }

        // match up roots
        ans := make([dynamic][N_VARS]C)
        for i in 0..<len(polynomial_index_to_roots[0])
        {
            is_in_all_polynomials := true
            for j in 1..<N_VARS
            {
                is_in_polynomial_k := false
                for k in 0..<len(polynomial_index_to_roots[j])
                {
                    is_in_polynomial_k ||= roots_match(polynomial_index_to_roots[j][k], polynomial_index_to_roots[0][i])
                }
                is_in_all_polynomials &&= is_in_polynomial_k
            }
            if is_in_all_polynomials
            {
                append(&ans, polynomial_index_to_roots[0][i])
            }
        }

        for i in 0..<len(polynomial_index_to_roots)
        {
            delete(polynomial_index_to_roots[i])
        }
        return ans[:]
    }
}
