package prop_test

import "core:testing"
import "core:log"
import "core:strings"
import "core:fmt"
import "base:runtime"
import "core:sync/chan"
import "core:time"
import "core:mem"

/*
This file contains a property based testing libary used to test implementations.
It is fairly simple and unfinished but it is good enough to test most implementations.
One nice thing about this libary is when a proposition is falseified it only shows logs for the invocation that falseified it.
*/

/*
Note on implementing your own generator:
- T: is the expected output type of the generator
- raw: allows your other functions to access any nessisary state
- generate: called to generate a random value of type T
- reduce: called to find a smaller counter example. Given an input of type T it should randomly generate a smaller example that might also fail the proposition.
- delete: called to free values of type T
- print: called to print values of type T when the proposition is falsefied
*/
Generator :: struct($T : typeid)
{
    raw : rawptr,
    generate : proc(rawptr) -> T,
    reduce : proc(rawptr, T) -> T,
    delete : proc(T),
    print : proc(builder : ^strings.Builder, t : T),
}

PropBasedLogMessage :: struct {
    level: runtime.Logger_Level,
	text: string,
}

CheckLoggerData :: struct{
    t : ^testing.T,
    old_logger : runtime.Logger,
}

PropBasedTestState :: struct
{
    logs : [dynamic]PropBasedLogMessage,
    logger : runtime.Logger,
    logger_data : CheckLoggerData
}

@(thread_local) prop_based_test_state : PropBasedTestState

reset_state :: proc(t : ^testing.T)
{
    if cap(prop_based_test_state.logs) > 0
    {
        resize(&prop_based_test_state.logs, 0)
    }
    else
    {
        prop_based_test_state.logs = make([dynamic]PropBasedLogMessage)
    }
    prop_based_test_state.logger_data = CheckLoggerData{t, context.logger}
    prop_based_test_state.logger = runtime.Logger{
        check_logger_proc,
        rawptr(&prop_based_test_state.logger_data),
        runtime.Logger_Level.Debug,
        nil
    }
}

delete_state :: proc()
{
    if cap(prop_based_test_state.logs) > 0
    {
        shrink(&prop_based_test_state.logs, 0)
    }
}

check_logger_proc :: proc(logger_data_raw: rawptr, level: runtime.Logger_Level, text: string, options: bit_set[runtime.Logger_Option], location := #caller_location)
{
    logger_data := cast(^CheckLoggerData)logger_data_raw
    cloned_text, clone_error := strings.clone(text, logger_data.t._log_allocator)
    assert(clone_error == nil, "Error while cloning string in test thread logger proc.")

    append(
        &prop_based_test_state.logs,
        PropBasedLogMessage{
            level = level,
    		text = cloned_text
        }
    )
}

print_falsification :: proc(loc := #caller_location)
{
    for l in prop_based_test_state.logs
    {
        log.log(l.level, l.text, location = loc)
    }
}

check_debug_assertion_failure_proc :: proc(prefix, message: string, loc := #caller_location) -> !
{
    log.error(loc, prefix, ":", message, location = loc)
    context.logger = (cast(^CheckLoggerData)context.logger.data).old_logger
    print_falsification(loc)

	runtime.trap()
}

log_args_1 :: proc(a_1 : ^$T, g_1 : Generator(T))
{
    sb := strings.builder_make()
    fmt.sbprintln(&sb, "Falsified with")

    fmt.sbprint(&sb, "a_1 = ")
    g_1.print(&sb, a_1^)
    fmt.sbprintln(&sb, "")

    log.error(strings.to_string(sb))
    strings.builder_destroy(&sb)
}

log_args_2 :: proc(a_1 : ^$T, g_1 : Generator(T), a_2 : ^$U, g_2 : Generator(U))
{
    sb := strings.builder_make()
    fmt.sbprintln(&sb, "Falsified with")

    fmt.sbprint(&sb, "a_1 = ")
    g_1.print(&sb, a_1^)
    fmt.sbprintln(&sb, "")

    fmt.sbprint(&sb, "a_2 = ")
    g_2.print(&sb, a_2^)
    fmt.sbprintln(&sb, "")

    log.error(strings.to_string(sb))
    strings.builder_destroy(&sb)
}

log_args_3 :: proc(a_1 : ^$T, g_1 : Generator(T), a_2 : ^$U, g_2 : Generator(U), a_3 : ^$V, g_3 : Generator(V))
{
    sb := strings.builder_make()
    fmt.sbprintln(&sb, "Falsified with")

    fmt.sbprint(&sb, "a_1 = ")
    g_1.print(&sb, a_1^)
    fmt.sbprintln(&sb, "")

    fmt.sbprint(&sb, "a_2 = ")
    g_2.print(&sb, a_2^)
    fmt.sbprintln(&sb, "")

    fmt.sbprint(&sb, "a_3 = ")
    g_3.print(&sb, a_3^)
    fmt.sbprintln(&sb, "")

    log.error(strings.to_string(sb))
    strings.builder_destroy(&sb)
}

check :: proc{
    check_1,
    check_2,
    check_3,
}

check_1 :: proc(t: ^testing.T,
    state : $S, g : Generator($T),
    predicate : proc(S, T) -> bool, itterations := 100,
    loc := #caller_location
)
{
    a_1 : T
    found_counter_example := false
    for i in 0..<itterations
    {
        a_1 = g.generate(g.raw)

        reset_state(t)
        context.assertion_failure_proc = check_debug_assertion_failure_proc
        context.logger = prop_based_test_state.logger

        log_args_1(&a_1, g)

        if !predicate(state, a_1)
        {
            found_counter_example = true
            break
        }
        g.delete(a_1)
    }

    if !found_counter_example
    {
        delete_state()
        return
    }

    // try to find a smaller counter example
    for _ in 0..<(itterations * 10)
    {
        new_a_1 := g.reduce(g.raw, a_1)

        reset_state(t)
        context.assertion_failure_proc = check_debug_assertion_failure_proc
        context.logger = prop_based_test_state.logger

        log_args_1(&new_a_1, g)

        if !predicate(state, new_a_1)
        {
            g.delete(a_1)
            a_1 = new_a_1
        }
        else
        {
            g.delete(new_a_1)
        }
    }

    {
        reset_state(t)
        context.assertion_failure_proc = check_debug_assertion_failure_proc
        context.logger = prop_based_test_state.logger

        log_args_1(&a_1, g)

        predicate(state, a_1)
    }

    print_falsification(loc)
}



check_2 :: proc(
    t: ^testing.T,
    state : $S, g_1 : Generator($T), g_2 : Generator($U),
    predicate : proc(S, T, U) -> bool, itterations := 100,
    loc := #caller_location
)
{
    a_1 : T
    a_2 : T
    found_counter_example := false
    for i in 0..<itterations
    {
        a_1 = g_1.generate(g_1.raw)
        a_2 = g_2.generate(g_2.raw)

        reset_state(t)
        context.assertion_failure_proc = check_debug_assertion_failure_proc
        context.logger = prop_based_test_state.logger

        log_args_2(&a_1, g_1, &a_2, g_2)

        if !predicate(state, a_1, a_2)
        {
            found_counter_example = true
            break
        }
        g_1.delete(a_1)
        g_2.delete(a_2)
    }

    if !found_counter_example
    {
        delete_state()
        return
    }

    // try to find a smaller counter example
    for _ in 0..<(itterations * 10)
    {
        new_a_1 := g_1.reduce(g_1.raw, a_1)
        new_a_2 := g_2.reduce(g_2.raw, a_2)

        reset_state(t)
        context.assertion_failure_proc = check_debug_assertion_failure_proc
        context.logger = prop_based_test_state.logger

        log_args_2(&new_a_1, g_1, &new_a_2, g_2)

        if !predicate(state, new_a_1, new_a_2)
        {
            g_1.delete(a_1)
            g_2.delete(a_2)
            a_1 = new_a_1
            a_2 = new_a_2
        }
        else
        {
            g_1.delete(new_a_1)
            g_2.delete(new_a_2)
        }
    }

    {
        reset_state(t)
        context.assertion_failure_proc = check_debug_assertion_failure_proc
        context.logger = prop_based_test_state.logger

        log_args_2(&a_1, g_1, &a_2, g_2)

        predicate(state, a_1, a_2)
    }

    print_falsification(loc)
}

check_3 :: proc(
    t: ^testing.T,
    state : $S, g_1 : Generator($T), g_2 : Generator($U), g_3 : Generator($V),
    predicate : proc(S, T, U, V) -> bool, itterations := 100,
    loc := #caller_location
)
{
    a_1 : T
    a_2 : T
    a_3 : T
    found_counter_example := false
    for i in 0..<itterations
    {
        a_1 = g_1.generate(g_1.raw)
        a_2 = g_2.generate(g_2.raw)
        a_3 = g_3.generate(g_3.raw)

        reset_state(t)
        context.assertion_failure_proc = check_debug_assertion_failure_proc
        context.logger = prop_based_test_state.logger

        log_args_3(&a_1, g_1, &a_2, g_2, &a_3, g_3)

        if !predicate(state, a_1, a_2, a_3)
        {
            found_counter_example = true
            break
        }
        g_1.delete(a_1)
        g_2.delete(a_2)
        g_3.delete(a_3)
    }

    if !found_counter_example
    {
        delete_state()
        return
    }

    // try to find a smaller counter example
    for _ in 0..<(itterations * 10)
    {
        new_a_1 := g_1.reduce(g_1.raw, a_1)
        new_a_2 := g_2.reduce(g_2.raw, a_2)
        new_a_3 := g_3.reduce(g_3.raw, a_3)

        reset_state(t)
        context.assertion_failure_proc = check_debug_assertion_failure_proc
        context.logger = prop_based_test_state.logger

        log_args_3(&new_a_1, g_1, &new_a_2, g_2, &new_a_3, g_3)

        if !predicate(state, new_a_1, new_a_2, new_a_3)
        {
            g_1.delete(a_1)
            g_2.delete(a_2)
            g_3.delete(a_3)
            a_1 = new_a_1
            a_2 = new_a_2
            a_3 = new_a_3
        }
        else
        {
            g_1.delete(new_a_1)
            g_2.delete(new_a_2)
            g_3.delete(new_a_3)
        }
    }

    {
        reset_state(t)
        context.assertion_failure_proc = check_debug_assertion_failure_proc
        context.logger = prop_based_test_state.logger

        log_args_3(&a_1, g_1, &a_2, g_2, &a_3, g_3)

        predicate(state, a_1, a_2, a_3)
    }

    print_falsification(loc)
}
