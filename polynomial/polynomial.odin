// implementation of polynomials field over some underling algebraic structures.
package polynomial
import "core:math"
import "core:math/cmplx"
import "core:slice"
import "base:intrinsics"
import "core:log"
import "core:mem"
import "core:fmt"
import "core:strings"
import "../algebraic_structures/ring"
import "../algebraic_structures/field"
import "../algebraic_structures/euclidean_ring"

/*
This structure represents a polynomial of any degree.
This should not be constructed directly the make_from_coefficents function should be used instead.
The coefficents are stored so that there index is the power of x.
The highest power coefficent should never be zero.

Inputs:
- $T: the type of the coefficents
- $ST: the type of the algebraic structure used to operate on the coefficents

Example:
	Polynomial(f32, Numeric(f32))
	Polynomial(Polynomial(f32, Numeric(f32)), EuclideanRing(f32))

*/
Polynomial :: struct($T : typeid, $ST : typeid)
{
    coefficents : [dynamic]T,
    algebraic_structure : ST
}

// used to make uninitialized polynomials unless you set degree to -1 the returned polynomial will not be valid
// since all its coefficents will be 0
make_uninitialized :: proc{
    make_uninitialized_numeric,
    make_uninitialized_algebraic_structure,
}

make_uninitialized_numeric :: proc($T : typeid, degree : int) ->
    Polynomial(T, field.NumericField(T)) where intrinsics.type_is_numeric(T)
{
    ans := Polynomial(T, field.NumericField(T)){}
    ans.coefficents = make([dynamic]T, degree + 1)
    return ans
}

make_uninitialized_algebraic_structure :: proc($T : typeid, algebraic_structure : $ST, degree : int) ->
    Polynomial(T, ST)
{
    ans := Polynomial(T, ST){}
    ans.coefficents = make([dynamic]T, degree + 1)
    ans.algebraic_structure = algebraic_structure
    return ans
}

/*
Makes a polynomial from the coefficents.
Clones the slice so the slice can go off the stack.
Does not clone the underlying data structures.
*/
make_from_coefficents :: proc{

    make_from_coefficents_numeric,
    make_from_coefficents_algebraic_structure,
}

make_from_coefficents_numeric :: proc($T : typeid, coefficents : []T, allocator := context.allocator) ->
    Polynomial(T, field.NumericField(T)) where intrinsics.type_is_numeric(T)
{
    ans := Polynomial(T, field.NumericField(T)){}
    ans.coefficents = slice.clone_to_dynamic(coefficents, allocator)
    assert(is_valid(ans))
    return ans
}

make_from_coefficents_algebraic_structure :: proc($T : typeid, algebraic_structure : $ST, coefficents : []T, allocator := context.allocator) ->
    Polynomial(T, ST)
{
    ans := Polynomial(T, ST){}
    ans.coefficents = slice.clone_to_dynamic(coefficents, allocator)
    ans.algebraic_structure = algebraic_structure
    assert(is_valid(ans))
    return ans
}

// determines if a polynomial is valid a polynomial is valid if it is the zero polynomial
// or its leading coefficent is not zero
is_valid :: proc(p : Polynomial($T, $ST)) -> bool
{
    if len(p.coefficents) == 0
    {
        return true
    }
    when ST == field.NumericField(T) || ST == euclidean_ring.EuclideanRing(T)
    {
        return p.coefficents[len(p.coefficents) - 1] != 0
    }
    else
    {
        return !p.algebraic_structure.eq(p.coefficents[len(p.coefficents) - 1], p.algebraic_structure.add_identity)
    }
}

// shrinks a polynomial that may or may not be valid to a valid polynomial by removing leading zeros
shrink_to_valid :: proc(p : ^Polynomial($T, $ST))
{
    when ST == field.NumericField(T) || ST == euclidean_ring.EuclideanRing(T)
    {
        i := len(p.coefficents) - 1
        for i >= 0 && p.coefficents[i] == 0
        {
            unordered_remove(&p.coefficents, i)
            i -= 1
        }
    }
    else
    {
        i := len(p.coefficents) - 1
        for i >= 0 && p.algebraic_structure.eq(p.coefficents[i], p.algebraic_structure.add_identity)
        {
            p.algebraic_structure.delete(p.coefficents[i])
            unordered_remove(&p.coefficents, i)
            i -= 1
        }
    }
}

// returns the degree of a polynomial -1 is returned of the zero polynomial
degree :: proc(p : Polynomial($T, $ST)) -> int
{
    assert(is_valid(p))
    return len(p.coefficents) - 1
}

resize_or_init_polynomial :: proc(p : ^Polynomial($T, $ST), algebraic_structure : ST, new_degree : int, loc := #caller_location)
{
    if cap(p.coefficents) == 0
    {
        // l has not yet been initalized so we initalize it
        p.coefficents = make([dynamic]T, context.allocator, loc)
        p.algebraic_structure = algebraic_structure
    }

    old_degree := degree(p^)
    if old_degree < new_degree
    {
        resize(&p.coefficents, new_degree + 1, loc)
    }
    if old_degree > new_degree
    {
        when ST != field.NumericField(T)
        {
            for i in (new_degree + 1)..=old_degree
            {
                p.algebraic_structure.delete(p.coefficents[i])
            }
        }
        resize(&p.coefficents, new_degree + 1, loc)
    }
}
