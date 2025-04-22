package polynomial
import "../prop_based"
import "core:math/rand"
import "core:strings"


PolynomialGeneratorInfo :: struct($T : typeid, $ST : typeid)
{
    coefficient_generator : prop_based.Generator(T),
    coefficient_algebraic_structure : ST
}

// makes a generator for polynomials given a generator of there coefficients
// used for property based testing of polynomials
make_generator :: proc(
    coefficient_generator : prop_based.Generator($T),
    coefficient_algebraic_structure : $ST
) -> prop_based.Generator(Polynomial(T, ST))
{
    generator_info_ptr := new(PolynomialGeneratorInfo(T, ST))
    generator_info_ptr.coefficient_generator = coefficient_generator
    generator_info_ptr.coefficient_algebraic_structure = coefficient_algebraic_structure

    generate_poly :: proc(generator_info_raw : rawptr) -> Polynomial(T, ST)
    {
        generator_info := (cast(^PolynomialGeneratorInfo(T, ST))generator_info_raw)^

        n := rand.uint64() % 8
        if n == 7
        {
            return make_uninitialized(T, generator_info.coefficient_algebraic_structure, -1)
        }
        ans := make_uninitialized(T, generator_info.coefficient_algebraic_structure, int(n))
        for i in 0..=n
        {
            ans.coefficients[i] = generator_info.coefficient_generator.generate(
                generator_info.coefficient_generator.raw
            )
        }
        shrink_to_valid(&ans)
        return ans
    }

    reduce_poly :: proc(generator_info_raw : rawptr, p : Polynomial(T, ST)) ->
        Polynomial(T, ST)
    {
        generator_info := (cast(^PolynomialGeneratorInfo(T, ST))generator_info_raw)^

        ans : Polynomial(T, ST)
        set(&ans, p)
        if degree(p) == -1
        {
            return ans
        }

        if rand.uint64() % 2 == 0
        {
            // remove a coefficient
            to_remove := rand.uint64() % u64(degree(p) + 1)
            ordered_remove(&ans.coefficients, int(to_remove))
        }
        else
        {
            // reduce a coefficient
            to_reduce := rand.uint64() % u64(degree(p) + 1)
            new_coefficient := generator_info.coefficient_generator.reduce(
                generator_info.coefficient_generator.raw,
                ans.coefficients[to_reduce]
            )
            generator_info.coefficient_algebraic_structure.set(&ans.coefficients[to_reduce], new_coefficient)
            generator_info.coefficient_generator.delete(new_coefficient)
        }

        shrink_to_valid(&ans)
        return ans
    }

    delete_poly :: proc(p : Polynomial(T, ST))
    {
        delete_polynomial(p)
    }

    print_poly :: proc(sb : ^strings.Builder, p : Polynomial(T, ST))
    {
        sb_print_polynomial(sb, p)
    }

    ans := prop_based.Generator(Polynomial(T, ST)){
        rawptr(generator_info_ptr),
        generate_poly,
        reduce_poly,
        delete_poly,
        print_poly
    }
    return ans
}

delete_generator :: proc(gen : prop_based.Generator(Polynomial($T, $ST)))
{
    free(cast(^PolynomialGeneratorInfo(T, ST))gen.raw)
}
