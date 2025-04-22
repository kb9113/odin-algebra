package euclidean_ring
import "../integral_domain"
import "core:mem"

/*
Interface for a Euclidean Ring:
- euclidean_div - called to perform the operation euclidean_div operation such that left == right * quotent + remainder where remainder == 0 or norm(remainder) < norm(right)
- norm - rough messure of size for a type
- all functions can be called where 2 or 3 input paramters point to the same piece of memory.
*/
EuclideanRing :: struct($T : typeid)
{
    using integral_domain : integral_domain.IntegralDomain(T),
    euclidean_div : proc(quotent : ^T, remainder : ^T, left : T, right : T),
    norm : proc(left : T) -> u64
}

NumericEuclideanRing :: struct($T : typeid)
{

}

gcd :: proc(p : $T, q : T, ring : EuclideanRing(T)) -> T
{
    quot, rem : T
    ring.euclidean_div(&quot, &rem, p, q)
    defer ring.delete(quot)
    defer ring.delete(rem)

    if ring.eq(ring.add_identity, rem)
    {
        ans : T
        ring.set(&ans, q)
        return ans
    }
    return gcd(q, rem, ring)
}

euclidean_div_f32 :: proc(quot : ^f32, rem : ^f32, l : f32, r : f32)
{
    quot^ = l / r
    rem^ = 0
}

norm_f32 :: proc(f : f32) -> u64
{
    if f == 0 { return 0 }
    else { return 1 }
}

EUCLIDEAN_RING_F32 :: EuclideanRing(f32){
    integral_domain.INTEGRAL_DOMAIN_F32,
    euclidean_div_f32,
    norm_f32
}

euclidean_div_u32 :: proc(quot : ^u32, rem : ^u32, l : u32, r : u32)
{
    quot^ = l / r
    rem^ = l % r
}

norm_u32 :: proc(u : u32) -> u64
{
    return u64(u)
}

EUCLIDEAN_RING_U32 :: EuclideanRing(u32){
    integral_domain.INTEGRAL_DOMAIN_U32,
    euclidean_div_u32,
    norm_u32
}

euclidean_div_i64 :: proc(quot : ^i64, rem : ^i64, l : i64, r : i64)
{
    if r == 0 { panic("cannot divide by 0") }
    quot^ = l / r
    rem^ = l % r
}

norm_i64 :: proc(u : i64) -> u64
{
    return u64(abs(u))
}

EUCLIDEAN_RING_I64 :: EuclideanRing(i64){
    integral_domain.INTEGRAL_DOMAIN_I64,
    euclidean_div_i64,
    norm_i64
}
