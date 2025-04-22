/*
Base interface which everything builds upon:
- set - called to perform the operation ans = right
- delete - called to free the memory used by a value of type T
- eq - called to perform the operation left == right
- print - called to write a printable version of a value of type T to a string builder
- set can be called where ans has not yet been "initialized"
*/
package base
import "core:mem"
import "core:strings"
import "core:fmt"
import "core:log"

/*
Interface for Base:
- set - called to perform the operation ans = right
- delete - called to free the memory used by a value of type T
- eq - called to perform the operation left == right
- print - called to write a printable version of a value of type T to a string builder
- set can be called where ans has not yet been "initialized"
*/
Base :: struct($T : typeid)
{
    set : proc(left : ^T, right : T),
    delete : proc(left : T),
    eq : proc(left : T, right : T) -> bool,
    print : proc(builder : ^strings.Builder, left : T),
}

log_base_object :: proc(b : Base($T), prefix : string, t : T)
{
    sb := strings.builder_make()
    b.print(&sb, t)
    log.info(prefix, strings.to_string(sb))
    strings.builder_destroy(&sb)
}

set_f32 :: proc(l : ^f32, r : f32) { l^ = r }
delete_f32 :: proc(l : f32) {}
print_f32 :: proc(builder : ^strings.Builder, l : f32) { fmt.sbprint(builder, l) }
eq_f32 :: proc(l : f32, r : f32) -> bool { return abs(l - r) < 1e-4 }

BASE_F32 :: Base(f32){
    set_f32,
    delete_f32,
    eq_f32,
    print_f32,
}

set_u32 :: proc(l : ^u32, r : u32) { l^ = r }
delete_u32 :: proc(l : u32) {}
print_u32 :: proc(builder : ^strings.Builder, l : u32) { fmt.sbprint(builder, l) }
eq_u32 :: proc(l : u32, r : u32) -> bool { return l == r }

BASE_U32 :: Base(u32){
    set_u32,
    delete_u32,
    eq_u32,
    print_u32,
}

set_i32 :: proc(l : ^i32, r : i32) { l^ = r }
delete_i32 :: proc(l : i32) {}
print_i32 :: proc(builder : ^strings.Builder, l : i32) { fmt.sbprint(builder, l) }
eq_i32 :: proc(l : i32, r : i32) -> bool { return l == r }

BASE_I32 :: Base(i32){
    set_i32,
    delete_i32,
    eq_i32,
    print_i32,
}

set_i64 :: proc(l : ^i64, r : i64) { l^ = r }
delete_i64 :: proc(l : i64) {}
print_i64 :: proc(builder : ^strings.Builder, l : i64) { fmt.sbprint(builder, l) }
eq_i64 :: proc(l : i64, r : i64) -> bool { return l == r }

BASE_I64 :: Base(i64){
    set_i64,
    delete_i64,
    eq_i64,
    print_i64,
}
