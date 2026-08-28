---
name: tcl-proc-generator
description: Generate production-quality Tcl code structured as procs (never loose top-level code) — a main proc plus helper procs, with error-defensive input validation at the top of every proc, a trailing debug flag, foreach-based looping, and "proc <name>:" error messages. Use this whenever the user asks to write, generate, create, or fix Tcl/TCL code, a Tcl script, procedure, or proc — or to write a description/summary of a Tcl proc. 生成结构化为 proc 的 Tcl 代码（主 proc 在前、辅助 proc 以下划线开头），每个 proc 带错误防御、末尾 debug 开关、foreach 遍历。当用户要求编写、生成、创建或修改 Tcl/TCL 代码、脚本或 proc，或为 proc 编写 description/说明时使用。
---

# Tcl Proc Generator

Generate Tcl the way a careful Tcl engineer would: as a set of self-contained **procedures (procs)**, not a loose sequence of commands. Every proc is defensive about its inputs, debuggable, and bounded in its loops. When asked for Tcl, produce that structure by default.

## Core structure

- Everything the user asks for becomes **procs**, never bare top-level code.
- A single Tcl file may hold multiple procs. The **first proc is the main proc** — it directly implements the user's requirement. Any procs after it are **helper/sub procs** that the main proc (or another helper) calls to do smaller tasks.
- If the task needs no helper, write only the main proc.
- Name the main proc after what it does (`compute_stats`, `read_netlist`, `parse_log`).
- Name helper/sub procs with a **leading underscore** to mark them as internal helpers, followed by a verb/noun name for their subtask (`_median_value`, `_validate_path`). The underscore is the signal that the proc is not the entry point — the main proc has no underscore.

## Error defense (top of every proc)

Before any real work, validate every input so a bad argument fails loudly and immediately instead of poisoning downstream logic. Check, in order:

1. **Presence** — required args are not empty strings.
2. **Type** — `string is integer`, `string is double`, `string is list`, etc.
3. **Format** — matches an expected pattern via `regexp` / `string match`.
4. **Content** — value is in an allowed set or range (`lsearch`, comparisons).

For lists, first guard with `catch {llength $arg}` — this is the reliable way to reject a malformed list before iterating it. Then validate each element with `foreach`.

Each failed check exits with `error` (see below). Never `return` a sentinel value silently when an input is wrong — that hides the bug and lets execution continue on bad data.

## The debug flag

- Append a `debug` parameter as the **last** parameter of every proc, default `0`.
- When `0` (default): no extra output. When `1`: print progress with `if {$debug} { puts "DEBUG <procname>: ..." }` at key steps — inputs received, intermediate values, which branch was taken.
- If a proc's end result benefits from a summary, emit it **only when debug is on**, after the work is done. Use a small aligned table (`format` with fixed widths) when there are several numbers; use a single prose line when there is just one.

## Exiting on error

When a check fails or execution hits a problem, stop immediately with `error`. Format the message as:

`proc <procname>: <why it failed, and what was expected>`

- `<procname>` is the name of the proc currently executing (the one raising the error).
- After the colon, say **why** it failed and **what valid input looks like**, so the caller can fix it without reading the source.
- Example: `error "proc compute_stats: element 'abc' is not a number. Expected every element of 'values' to be numeric."`

## Loops: foreach only

- Use `foreach` for every iteration. It is bounded by the list's length, so it cannot loop forever — a real debugging hazard when `for`/`while` conditions are written wrong.
- Avoid `for {set i 0} {...} {incr i}` and `while {...}`. When you need a count or an index, iterate the values directly, or use `foreach i [lsort $list]`, `foreach {k v} $list` for pairs, or `foreach item $list {incr n}` to count.

## Variable scope: no global

- Do not use `global`. Pass data in through parameters and out through `return` (use `upvar` only when a caller explicitly needs a variable updated in place). This keeps each proc self-contained and its behavior predictable.

## Parameter ordering

- All params come from a **fixed list** — no `args`.
- Params **without defaults** come first, ordered by the sequence the proc actually uses them.
- Params **with defaults** come after, ordered by importance (most important first).
- The `debug` param is always last.

## Style and language

- **Indentation**: use exactly **2 spaces** per level — never tabs, never 4 spaces.
- **Language**: write the entire Tcl script in **English** — all comments, the proc description, every `error` message, and all debug output. Do not use Chinese or any other language inside the code.

## Output format

After generating the code, write it to a file and deliver both the file and an explanation:

1. **Write the code to a `.tcl` file** in the current directory, named after the main proc: `<main_proc_name>.tcl`. A main proc `check_file` produces `check_file.tcl`. The file holds the complete, runnable Tcl code (all procs) followed by an inert test block (see "Test code section").
2. **A detailed explanation** (in the reply) of each proc: what its error-defense checks catch, how its debug output works, and its logic/flow — including which helper procs it calls and why. Explain the main proc's contract: required vs defaulted params and the shape of the return value.

## Test code section

Every generated script ends with a test block wrapped in `if {0} { ... }`, so it is inert by default — the user runs it by changing the `0` to `1` and running `tclsh <file>.tcl`. Write **3 test cases by default** that cover the proc's functionality end to end: the normal/happy path, an edge case, and an error path (asserting the proc raises `error` as expected). Add more only if the proc has more distinct behaviors.

Each test compares the actual result to the expected result and records pass/fail. After all tests run, print a **summary table** listing each test's name, expected output, actual output, and pass/fail result, so mismatches are obvious at a glance.

```tcl
# ---- Test code: change the 0 to 1 to run ----
if {0} {
  set pass 0
  set fail 0
  set rows {}

  # Test 1 — normal input
  set name "3 values"; set expected {count 3 mean 20.0 median 20.0}
  set actual [compute_stats {10 20 30}]
  if {$actual == $expected} { incr pass; set status PASS } else { incr fail; set status FAIL }
  lappend rows [list $name $expected $actual $status]

  # Test 2 — edge case (even number of values)
  set name "even count"; set expected {count 4 mean 2.5 median 2.5}
  set actual [compute_stats {1 2 3 4}]
  if {$actual == $expected} { incr pass; set status PASS } else { incr fail; set status FAIL }
  lappend rows [list $name $expected $actual $status]

  # Test 3 — error path (non-numeric element must raise error)
  set name "non-numeric errors"; set expected "error"
  if {[catch {compute_stats {1 2 x}} msg]} {
    incr pass; set status PASS; set actual "error"
  } else {
    incr fail; set status FAIL; set actual "no error"
  }
  lappend rows [list $name $expected $actual $status]

  # Summary table
  puts [format "%-18s %-24s %-16s %s" "test" "expected" "actual" "result"]
  foreach r $rows {
    puts [format "%-18s %-24s %-16s %s" [lindex $r 0] [lindex $r 1] [lindex $r 2] [lindex $r 3]]
  }
  puts [format "passed: %d   failed: %d" $pass $fail]
}
```

## Testing and debugging loop (via tclsh)

Tests are validated only by **execution**, never by reading the code. Do not judge whether the test or the proc is correct by inspection alone — always run it with `tclsh` and check the actual output. Never declare a test correct without having run `tclsh` and seen its output.

1. **Run the tests**: flip the `if {0}` flag to `1` and execute `tclsh <file>.tcl`. Capture the complete output — both normal `puts` output and any error output (stderr). Actually run the command and collect stdout/stderr; do not simulate or guess the result.
2. **Compare** the captured output against the summary table's expected/actual values.
3. If everything matches, the proc is done.
4. If something mismatches, diagnose in this order:
   - **First, the test code** — check whether the test itself is wrong (wrong expected value, wrong input, wrong comparison). If so, fix the test.
   - **Then, the proc under test** — if the test is correct, the bug is in the proc. Fix the proc directly when you can solve it.
5. Re-run `tclsh` after each fix and re-check the output.
6. After **3** rounds of fix-and-retest, if it still will not pass, **stop**. Report to the user: what problem appeared, its concrete manifestation (the exact output that differed from expectation), and your judgment of where in the code the error lies. Then ask the user how to proceed — do not keep iterating silently.

## When to pause and ask

If the user's request leaves a real fork in the road — what the input format is, what the expected return shape is, which of two behaviors they want — stop and ask before writing, rather than guessing and generating the wrong contract. Confirm intent, then proceed.

## Proc description (on request only)

This is a **separate, opt-in** output. Do not generate a description automatically while writing the proc. The user asks for it at the wrap-up stage — after the proc code is finalized — as a summary of that proc. Only produce it when the user explicitly asks for a "description" (or 描述 / 说明) of the proc; otherwise skip it.

When asked, write the description as a `#` comment header at the very top of the `.tcl` file, before the first proc, so the file stays runnable. Base it strictly on the final proc code and follow this structure, in order:

1. **功能概述 (overview)** — one or two concise sentences on what the proc does. If it has a notable special behavior (skips comment lines, preserves leading zeros, handles a rare edge case), add that — but stay brief, no long-winded prose.
2. **参数 (parameters)** — for each parameter: its **function** and the **allowed/expected input values** (type, format, range, valid enum values, default, and how an invalid value is handled).
3. **返回值 (return value)** — what the proc returns, including its shape/type (scalar vs key-value list) and that it raises `error` (with the `proc <name>:` prefix) instead of returning on failure.

Keep the whole thing tight and scannable. Write it in English, like the rest of the script.

**Example** — for `check_file {path {debug 0}}`, written as a `#` comment header at the top of `check_file.tcl`:

```tcl
# Overview: checks that a file exists and is readable, raising an error otherwise.
#
# Parameters:
#   path  (required, string)        - file path to verify; must be non-empty,
#                                     not all-whitespace, no NUL bytes.
#   debug (optional, 0/1, default 0) - when 1, prints progress + summary.
#
# Return value: 1 on success; on failure raises error with a
# "proc check_file:" message instead of returning.
```

## Full example

The following demonstrates every rule. Note the error-defense block at the top, the trailing `debug` flag, the `foreach` loops, the `proc <name>:` error prefix, and the summary table printed only when `debug` is on.

```tcl
# Main proc: compute statistics over a list of numbers.
#   values   - (required) list of numeric values
#   precision- (optional, default 2) decimal places for the mean/median
#   debug    - (optional, default 0) 1 = print progress + summary table
proc compute_stats {values {precision 2} {debug 0}} {
  # ---- Error defense ----
  if {$values eq ""} {
    error "proc compute_stats: 'values' is empty. Expected a non-empty list of numbers."
  }
  if {[catch {llength $values} err]} {
    error "proc compute_stats: 'values' is not a valid Tcl list ($err). Expected a list of numbers."
  }
  foreach v $values {
    if {![string is double -strict $v]} {
      error "proc compute_stats: element '$v' is not a number. Expected every element of 'values' to be numeric."
    }
  }

  set n [llength $values]
  if {$debug} { puts "DEBUG compute_stats: received $n values: $values" }

  # Sum via foreach (no for/while).
  set total 0.0
  foreach v $values { set total [expr {$total + $v}] }
  set mean [expr {$total / $n}]
  if {$debug} { puts "DEBUG compute_stats: mean = [format %.${precision}f $mean]" }

  # Median is delegated to a helper proc (note the leading underscore).
  set median [_median_value $values $debug]
  if {$debug} { puts "DEBUG compute_stats: median = [format %.${precision}f $median]" }

  if {$debug} {
    # Summary table, shown only when debug is enabled.
    puts "==== compute_stats summary ===="
    puts [format "%-12s %s"  "count"  $n]
    puts [format "%-12s %.*f" "mean"   $precision $mean]
    puts [format "%-12s %.*f" "median" $precision $median]
    puts "==============================="
  }

  return [list count $n mean $mean median $median]
}

# Helper proc: return the median of a numeric list (input assumed validated).
# The leading underscore marks it as an internal helper, not the entry point.
proc _median_value {values {debug 0}} {
  set sorted [lsort -real $values]
  if {$debug} { puts "DEBUG _median_value: sorted = $sorted" }
  set n [llength $sorted]
  set mid [expr {$n / 2}]
  if {$n % 2 == 1} {
    return [lindex $sorted $mid]
  } else {
    return [expr {([lindex $sorted [expr {$mid - 1}]] + [lindex $sorted $mid]) / 2.0}]
  }
}
```
