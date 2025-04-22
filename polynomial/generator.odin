package polynomial
import "../prop_based"
import "core:math/rand"
import "core:strings"


PolynomialGeneratorInfo :: struct($T : typeid, $ST : typeid)
{
    coefficent_generator : prop_based.Generator(T),
    coefficent_algebraic_structure : ST
}

// makes a generator for polynomials given a generator of there coefficents
// used for property based testing of polynomials
make_generator :: proc(
    coefficent_generator : prop_based.Generator($T),
    coefficent_algebraic_structure : $ST
) -> prop_based.Generator(Polynomial(T, ST))
{
    generator_info_ptr := new(PolynomialGeneratorInfo(T, ST))
    generator_info_ptr.coefficent_generator = coefficent_generator
    generator_info_ptr.coefficent_algebraic_structure = coefficent_algebraic_structure

    generate_poly :: proc(generator_info_raw : rawptr) -> Polynomial(T, ST)
    {
        generator_info := (cast(^PolynomialGeneratorInfo(T, ST))generator_info_raw)^

        n := rand.uint64() % 8
        if n == 7
        {
            return make_uninitialized(T, generator_info.coefficent_algebraic_structure, -1)
        }
        ans := make_uninitialized(T, generator_info.coefficent_algebraic_structure, int(n))
        for i in 0..=n
        {
            ans.coefficents[i] = generator_info.coefficent_generator.generate(
                generator_info.coefficent_generator.raw
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
            // remove a coefficent
            to_remove := rand.uint64() % u64(degree(p) + 1)
            ordered_remove(&ans.coefficents, int(to_remove))
        }
        else
        {
            // reduce a coefficent
            to_reduce := rand.uint64() % u64(degree(p) + 1)
            new_coefficent := generator_info.coefficent_generator.reduce(
                generator_info.coefficent_generator.raw,
                ans.coefficents[to_reduce]
            )
            generator_info.coefficent_algebraic_structure.set(&ans.coefficents[to_reduce], new_coefficent)
            generator_info.coefficent_generator.delete(new_coefficent)
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
