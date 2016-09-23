---
permalink: /understanding_dependent_types
---

# Understanding Dependent Types

Updated September 23, 2016
{: .small}

This tutorial is intended to give a first taste of dependent types in Idris. It can also be used as supplemental
reading for the [Dependent Types](http://docs.idris-lang.org/en/latest/tutorial/typesfuns.html#dependent-types)
section of the official [Idris Tutorial](http://docs.idris-lang.org/en/latest/tutorial/).

**Work in progress!** This tutorial has not yet been reviewed by the Idris community. The lead author, Dean,
is still new to Idris. See **Participating** in the left sidebar. Dean opened a [discussion thread]((https://groups.google.com/forum/#!topic/idris-lang/a5SdUl9W0KY)) about this
tutorial in the Idris Programming Language Google group.
{: .notice--warning}

[Wikipedia](https://en.wikipedia.org/wiki/Dependent_type) provides a good top-level definition of dependent types:

> A dependent type is a type whose definition depends on a value. A "pair of integers" is a type.
> A "pair of integers where the second is greater than the first" is a dependent type because of the dependence on the value.

Introductions to dependent types often use the example `Vect n a`, which represents a list of `n` values of type `a`.
For example, `Vect 3 String` is a list of 3 strings.

One way to create a `Vect` is to use the `replicate` function defined in the Idris standard library:

~~~
replicate : (n : Nat) -> (x : a) -> Vect n a
~~~

This declaration can be read as follows: "`replicate` is a function that takes a natural number `n` and
a value `x` of some arbitrary type `a`. It returns a `Vect` of length `n` having values of type `a`".
Notice how this fits Wikipedia's definition of a dependent type: the return type of `replicate` depends
on the value of one of `replicate`'s arguments.

At this point, you might reasonably imagine that this declaration of `replicate` works because the value of `n`
just feeds into a "parameter" of the `Vect` return type, rather than completely changing the return type.
(Technically we would call `n` an _index_ of `Vect`; the data type `a` is a _parameter_ of `Vect`.)
But in fact, the dependent type paradigm is fully general -- it's
[turtles all the way down](https://en.wikipedia.org/wiki/Turtles_all_the_way_down).

The return type of a function can be freely calculated from the values of its parameters. The following declaration,
for example, is strange but valid:

~~~
strange: (n : Nat) -> if n == 0 then Int else String
~~~

This declares `strange` as a function of a natural number `n`. If `n` is zero then it returns an `Int`.
Otherwise, it returns a `String`. The appearance of `if`/`then`/`else` in this type signature isn't a special case.
In Idris, types are first-class entities that can be computed and manipulated just like anything else.
Types and values don't live in separate sub-grammars; they can be freely mixed.
Values can be computed and referenced at compile time. Types can be computed and referenced at runtime.

Here is the complete definition of a suitable `strange` function:

~~~
strange : (n : Nat) -> if n == 0 then Int else String
strange Z = 0
strange (S k) = "positive"
~~~

__Note:__ The sample code for this chapter is in GitHub, in
[understanding_dependent_types.idr](https://github.com/idris-live/idris-live.github.io/blob/master/_sample_idris_code/understanding_dependent_types.idr).
{: .notice--info}

The data type `Nat` is declared in Idris' standard library to represent non-negative integers. The `Nat` type
turns out to be very useful in type signatures both because natural numbers come up frequently in the real world
(you never saw a list of -3 items, nor a list of 3.14 items), and because the `Nat` type is easy to manipulate
in ways that the Idris compiler understands. The Idris library declares two constructors for `Nat` values:
`Z` represents zero, while `S k` represents the successor of some other `Nat` called `k`.

In Idris, as in Haskell and some other functional languages, we can provide separate definitions for
the same function invoked with arguments matching different patterns.
In this case, we have defined `strange` to return `0` for `Z`, or  else `"positive"` for any `S k`.
We can try this out in the Idris REPL:

~~~
*strange> strange 0
0 : Int
*strange> strange 1
"positive" : String
*strange>
~~~

Demonstrating this in the REPL may give you the impression that you are seeing some form of dynamic typing.
The behavior shown above wouldn't look out of place in Python, for example. But in Idris, this is static
typing all the way down. Here is a function that uses `strange` correctly, and that compiles:

~~~
strangeLength : (s : String) -> if length s == 0 then Int else String
strangeLength s = strange (length s)
~~~

Here is a function that doesn't use `strange` correctly, and that fails type-checking:

~~~
-- Doesn't compile
strangeLengthBroken : (s : String) -> if length s == 0 then Int else String
strangeLengthBroken s = strange (length s + 1)
~~~

So what type does `strange` actually have? It has exactly the type we gave it:

~~~
*strange> :type strange
strange : (n : Nat) -> if n == 0 then Int else String
~~~

Early in one's journey into Idris, it may seem strange that unevaluated expressions (such as the
return type above) linger at compile time as real things. Most programming languages work more like calculators:
we may write down `x + 3` in the source code, but this just
represents the operation of adding `3` to some particular value stored in `x`. In Idris, the type system
understands `x + 3` as an expression involving an unknown `x` that may be related in specified ways
to other unknown values. It is helpful to think
of the Idris type system as more like algebra than like a calculator. (Technically, it is closer to a [typed lambda calculus](https://en.wikipedia.org/wiki/Typed_lambda_calculus),
but that's an unnecessarily intimidating name for what's going on.)

To provide a first glimpse of the expressive power of dependent types, let's look at some more functions involving
`Vect`s. Here is the declaration of an infix operator `++` that appends two `Vect`s:

~~~
(++) : Vect m a -> Vect n a -> Vect (m + n) a
~~~

That is quite expressive! `++` could conceivably do something other than append its two arguments,
but just from the type signature we'd be shocked if that wasn't what it did.

Let's look for a function involving `Vect`s where the type declaration may help prevent likely mistakes.
Here's a classic:

~~~
zip : Vect n a -> Vect n b -> Vect n (a, b)
~~~

The `zip` function is a basic operation of most functional programming. Given two lists of the same length,
it produces a list of corresponding pairs. For example, in the Idris REPL:

~~~
Idris> zip [1, 2, 3] ["a", "b", "c"]
[(1, "a"), (2, "b"), (3, "c")] : List (Integer, String)
~~~

The standard libraries of different functional programming languages differ on what `zip` should do if its
input lists have different lengths. In some languages, this is a runtime error. In others, excess elements of the
longer list are silently ignored. In Idris, calling `zip` on `Vect`s of different lengths is a compile-time error!
We can see this happen in the Idris REPL:

~~~
Idris> :module Data.Vect

*Data/Vect> Vect.zip [1, 2, 3] ["a", "b", "c"]
[(1, "a"), (2, "b"), (3, "c")] : Vect 3 (Integer, String)

*Data/Vect> Vect.zip [1, 2] ["a", "b", "c"]
(input):1:18:When checking argument xs to constructor Data.Vect.:::
        Type mismatch between
                Vect (S k) a (Type of x :: xs)
        and
                Vect 0 String (Expected type)

        Specifically:
                Type mismatch between
                        S k
                and
                        0
~~~

The error message is probably mystifying to an Idris newcomer, but for someone with just a little fluency
in Idris it is fairly readable. It essentially says that type-checking of the call
to `Vect.zip` failed as it recursed down through the recursive definition of the `Vect` data type,
when it eventually tried to match a non-zero-length `Vect` type with a zero-length `Vect` type.

Around now, you are probably wondering how the Idris compiler can possibly know at compile time whether
the lengths of two `Vect`s are the same. In the REPL example above, this is easy: we provided specific `Vect`
literals like `[1, 2, 3]` and `["a", "b", "c"]`, so it makes perfect sense that the compiler knows whether
our literals have the same length. But in general?

The answer is that when a type signature enforces a constraint involving runtime values, this places an
obligation on the Idris programmer to write the code in a way that enables the Idris compiler to see that
the constraint is always met. Sometimes, as in the example above that zips two literal `Vect`s, this is
very easy. Sometimes it is very difficult. As a community, we will have to learn when the benefits of
enforcing more constraints at compile-time are worth the extra effort of showing the compiler that the
constraints are met.

Here is an example of a function that does _not_ compile, because the Idris compiler correctly sees
that it may try to `Vect.zip` two lists of different lengths:

~~~
-- This does not compile.
zipReplicasBroken : (numAs : Nat) -> a -> (numBs : Nat) -> b -> Vect numAs (a, b)
zipReplicasBroken numAs valA numBs valB =
  let aVec = replicate numAs valA
      bVec = replicate numBs valB
  in Vect.zip aVec bVec
~~~

The Idris compiler gives an excellent error message (although the line breaks are added):

~~~
When checking right hand side of zipReplicasBroken with expected type Vect numAs (a, b)
When checking argument n to function Data.Vect.replicate:
Type mismatch between numAs (Inferred value) and numBs (Given value)
~~~

Here is an example of a similar function that does compile, because the Idris compiler can see from
how the code is written that it will not try to zip `Vect`s of different lengths:

~~~
zipReplicas : (n : Nat) -> a -> b -> Vect n (a, b)
zipReplicas n valA valB =
  let aVec = replicate n valA
      bVec = replicate n valB
  in Vect.zip aVec bVec
~~~

Here is an example of a similar function that you might wish would compile, because as a human
being you can see that the two vectors always have the same length, but that does not compile
because the Idris compiler is unconvinced:

~~~
-- This does not compile.
zipReplicasSuccessorBroken : (n : Nat) -> a -> b -> Vect (n + 1) (a, b)
zipReplicasSuccessorBroken n valA valB =
  let aVec = replicate (n + 1) valA
      bVec = valB :: replicate n valB
  in Vect.zip aVec bVec
~~~

In this case, Idris complains:

~~~
When checking right hand side of zipReplicasSuccessorBroken with expected type Vect (n + 1) (a, b)
Type mismatch between Vect (S n) b (Type of valB :: replicate n valB)
                  and Vect (plus n 1) b (Expected type)
Specifically: Type mismatch between S n and plus n 1
~~~

It's a great error message, but it shows the Idris compiler being a little dumb: it doesn't know that `S n`
(the successor of n) is the same as `plus n 1` (aka `n + 1`). Interestingly, the following is just barely different,
but does compile:

~~~
zipReplicasSuccessor : (n : Nat) -> a -> b -> Vect (1 + n) (a, b)
zipReplicasSuccessor n valA valB =
  let aVec = replicate (1 + n) valA
      bVec = valB :: replicate n valB
  in Vect.zip aVec bVec
~~~

All we changed to make this work was to say `1 + n` instead of `n + 1`.

At this point, you might want to throw your hands up in frustration! If I program in Idris, will I spend the
rest of my life trying to second-guess a stupid compiler? To some degree, the answer is surely yes, but with
a little more fluency this particular example becomes easy.

What's happening here is that the Idris standard library defines `plus` on `Nat` in such a way that the
Idris compiler can easily see that `1 + n` is equal to `S n`, but cannot easily see this about `n + 1`:

~~~
||| Add two natural numbers.
||| @ n the number to case-split on
||| @ m the other number
total plus : (n, m : Nat) -> Nat
plus Z right        = right
plus (S left) right = S (plus left right)
~~~

The keyword `total` declares that `plus` will terminate without error for all inputs. This is
verified by the Idris compiler. Only functions that are in fact _total_ (whether declared `total` or not)
are evaluated at compile time.

When the Idris compile sees

~~~
1 + n
~~~

It translates `1` into `S Z` -- the successor of `Nat`'s zero value -- giving it

~~~
S Z + n
~~~

It uses an interface definition for `+` in the standard library to translate this into

~~~
plus (S Z) n
~~~

From the definition of `plus` above, it translates this into

~~~
S (plus Z n)
~~~

But also from the definition of `plus`, it knows that `plus Z n = n`, giving it

~~~
S n
~~~

This is exactly what it needs to type-check `zipReplicasSuccessor` as defined above.

A more subtle reason to throw up our hands in frustration might be that our code just depended on
the _implementation_ of `plus`! If the definition of `plus` were changed to recurse on the right-hand
argument instead of the left-hand argument, our code would break. Doesn't that horribly break
encapsulation? No: the definition of `plus` is explicitly declared as `public export`, which
deliberately makes it transparent so the Idris type system can do algebra on it. (You can't see
this in the definition of `plus` above because `public export` is declared as a default for that whole file.)
If `plus` were instead just declared `export`, then uses of `plus` could only depend on its
type signature.

Ok, suppose we really do want to write `n + 1` in our type signature,
like we tried to do in `zipReplicasSuccessorBroken` above. To make this work,
we have to give the Idris compiler a little help to see our deeper truth.

You may remember from high-school algebra that addition is commutative: x + y = y + x.
To get `zipReplicasSuccessor2` to type-check, we have to explicitly point out
the commutativity of addition to the Idris compiler. This enables the compiler to
recognize that `bVec`'s type `Vect (S n) b` is the same as the expected type, `Vect (plus n 1) b`.

~~~
zipReplicasSuccessor2 : (n : Nat) -> a -> b -> Vect (n + 1) (a, b)
zipReplicasSuccessor2 n valA valB =
  let aVec = replicate (n + 1) valA
      bVec = valB :: replicate n valB
  in Vect.zip aVec (rewrite plusCommutative n 1 in bVec)
~~~

Yikes! Did the Idris compiler just force us to fill in the blanks on a high-school algebra proof
before it would compile our code? Yes, that's exactly what happened.

Is this a good thing? Time will tell, as the community explores the benefits and costs
of dependent types. But it is a plausible tradeoff. Dependent types allow us to
express invariants and function contracts in type signatures. We have to write our code
in such a way that the Idris compiler can verify these invariants and function contracts.
When we read the code, we can count on them. This goes a big step further with two arguments
commonly made for static typing:

* Since any given line of code is read and reasoned about far more often then it is modified,
  it is worth some extra time to express useful machine-verified invariants.

* We don't have to unit test what the compiler will verify.

Probably some of us will end up loving this and others will end up hating it.
But if you enjoy the solid footing that you get from traditional static types,
you may want to give dependent types a chance.
