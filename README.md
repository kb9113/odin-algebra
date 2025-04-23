# odin-algebra

Searchable documentation is available at https://calebmanning.net/algebra/.

An abstract algebra library written in odin. It implements interfaces for different algebraic structures as well as polynomials and rationals which operate over theses structures. This means algebraic objects can be composed to form more complicated algebraic structures. For example you can have polynomials with polynomial coefficients or represent the rational functions as a rational with polynomial numerator and denominator.

## Algebraic Structures
- Ring
- Commutative Ring
- Integral Domain
- Euclidean Ring
- Field

## Algebraic Objects
- Polynomial - implement the euclidean ring structure if the coefficients are a field
- Rational - implements the field structure

## Examples
This library implements all the basic operations you would expect to find on a polynomial as well as differentiation, integration, complex and real root finding and sub resultant sequence calculations. \
\
This means this library can be used to solve systems of multivariate polynomial equations.
```odin
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
```
## Todo
- Complex Fields similar to how Rationals work now
- Algebraic Numbers
