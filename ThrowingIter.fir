# Code for the blog post: https://osa1.net/posts/2025-04-17-throwing-iterators-fir.html

type Overflow:
    Overflow

type EmptyInput:
    EmptyInput

type InvalidDigit:
    InvalidDigit

sum(nums: Vec[U32]) U32:
    let result: U32 = 0
    for i: U32 in nums.iter():
        result += i
    result

parseSum(nums: Vec[Str]) U32:
    let result: U32 = 0
    for i: U32 in nums.iter().map(parseU32):
        result += i
    result

parseSumPropagateErrors(nums: Vec[Str]) U32 / [Overflow, EmptyInput, InvalidDigit, ..errs]:
    let result: U32 = 0
    for i: U32 in nums.iter().map(parseU32Exn):
        result += i
    result

parseSumHandleInvalidDigits(nums: Vec[Str]) U32 / [Overflow, EmptyInput, ..errs]:
    let result: U32 = 0
    for i: U32 in nums.iter().map(parseU32Exn).mapResult(handleInvalidDigit):
        result += i
    result

parseSumHandleInvalidDigitsLogRest(nums: Vec[Str]) U32:
    let result: U32 = 0
    for i: Result[[Overflow, EmptyInput], U32] in nums.iter().map(parseU32Exn).mapResult(handleInvalidDigit).try():
        match i:
            Result.Err(~Overflow.Overflow): print("Overflow")
            Result.Err(~EmptyInput.EmptyInput): print("Empty input")
            Result.Ok(i): result += i
    result

main():
    let nums: Vec[U32] = Vec.withCapacity(10)
    nums.push(1)
    nums.push(2)
    nums.push(3)
    print(sum(nums))

    let strs: Vec[Str] = Vec.withCapacity(10)
    strs.push("1")
    strs.push("2")
    strs.push("3")
    print(parseSum(strs))

    strs.push("a")
    match try(||: parseSumPropagateErrors(strs)):
        Result.Ok(sum): print(sum)
        Result.Err(~Overflow.Overflow): print("Overflow")
        Result.Err(~EmptyInput.EmptyInput): print("EmptyInput")
        Result.Err(~InvalidDigit.InvalidDigit): print("InvalidDigit")

    match try(||: parseSumHandleInvalidDigits(strs)):
        Result.Ok(sum): print(sum)
        Result.Err(~Overflow.Overflow): print("Overflow")
        Result.Err(~EmptyInput.EmptyInput): print("EmptyInput")

    strs.push("")
    strs.push("100000000000000000000000000000000")
    strs.push("4")

    print(parseSumHandleInvalidDigitsLogRest(strs))

####################################################################################################
#
#       Utils and helpers
#
####################################################################################################

handleInvalidDigit(parseResult: Result[[InvalidDigit, ..errs], Option[U32]]) Option[U32] / [..errs]:
    match parseResult:
        Result.Ok(result): result
        Result.Err(~InvalidDigit.InvalidDigit): Option.Some(u32(0))
        Result.Err(other): throw(other)

parseU32(s: Str) U32:
    if s.len() == 0:
        panic("Empty input")

    let result: U32 = 0

    for c: Char in s.chars():
        if c < '0' or c > '9':
            panic("Invalid digit")

        let digit = c.asU32() - '0'.asU32()

        result *= 10
        result += digit

    result

parseU32Exn(s: Str) U32 / [InvalidDigit, Overflow, EmptyInput, ..r]:
    if s.len() == 0:
        throw(~EmptyInput.EmptyInput)

    let result: U32 = 0

    for c: Char in s.chars():
        if c < '0' or c > '9':
            throw(~InvalidDigit.InvalidDigit)

        let digit = c.asU32() - '0'.asU32()

        result = match checkedMul(result, 10):
            Option.None: throw(~Overflow.Overflow)
            Option.Some(newResult): newResult

        result = match checkedAdd(result, digit):
            Option.None: throw(~Overflow.Overflow)
            Option.Some(newResult): newResult

    result

checkedAdd(i1: U32, i2: U32) Option[U32]:
    if i1 > u32(4294967295) - i2:
        return Option.None

    Option.Some(i1 + i2)

checkedMul(i1: U32, i2: U32) Option[U32]:
    let result = i1 * i2

    if i1 != 0 and result / i1 != i2:
        return Option.None

    Option.Some(result)

####################################################################################################
#
#       Test output
#
####################################################################################################

# NB. The first two lines should disappear with #49.

# expected stdout:
# 6
# 6
# InvalidDigit
# 6
# Empty input
# Overflow
# 10

# expected stderr:
# tests/ThrowingIter.fir:59:5: Unexhaustive pattern match
# tests/ThrowingIter.fir:65:5: Unexhaustive pattern match
