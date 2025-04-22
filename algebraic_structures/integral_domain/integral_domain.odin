/*
Interface for a Integral Domain
- cancel - called to perform a perfect division if left := a * right after cancel is called ans == a.
- this function is only called when the cancelation definitely works.
- this functions can be called where 2 or 3 input parameters point to the same piece of memory.
*/
package integral_domain
import "core:mem"
import "../ring"
import "core:strings"
import "core:fmt"
/*
Interface for a Integral Domain:
- cancel - called to perform a perfect division if left := a * right after cancel is called ans == a.
- this function is only called when the cancelation definitely works.
- this functions can be called where 2 or 3 input parameters point to the same piece of memory.
*/
IntegralDomain :: struct($T : typeid)
{
    using commutative_ring : ring.CommutativeRing(T),
    cancel : proc(ans : ^T, left : T, right : T)
}

cancel_f32 :: proc(a : ^f32, l : f32, r : f32) { a^ = l / r }

INTEGRAL_DOMAIN_F32 :: IntegralDomain(f32){
    ring.RING_F32,
    cancel_f32
}

cancel_u32 :: proc(a : ^u32, l : u32, r : u32) { a^ = l / r }

INTEGRAL_DOMAIN_U32 :: IntegralDomain(u32){
    ring.RING_U32,
    cancel_u32
}

cancel_i32 :: proc(a : ^i32, l : i32, r : i32) { a^ = l / r }

INTEGRAL_DOMAIN_I32 :: IntegralDomain(i32){
    ring.RING_I32,
    cancel_i32
}

cancel_i64 :: proc(a : ^i64, l : i64, r : i64)
{
    if r == 0 { panic("cannot cancel by 0") }
    if l != (l / r) * r { panic("invalid cancelation") }
    a^ = l / r
}

INTEGRAL_DOMAIN_I64 :: IntegralDomain(i64){
    ring.RING_I64,
    cancel_i64
}
