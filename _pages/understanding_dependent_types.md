---
permalink: /understanding_dependent_types
---

# Understanding Dependent Types

[Wikipedia](https://en.wikipedia.org/wiki/Dependent_type) provides a good top-level definition of dependent types:

> A dependent type is a type whose definition depends on a value. A "pair of integers" is a type.
> A "pair of integers where the second is greater than the first" is a dependent type because of the dependence on the value.

One canonical introductory example of a dependent type is `Vect n a`, which represents a list of `n` values of type `a`.
The Idris standard library declares a function `replicate` that creates a vector which repeats a specified value a
specified number of times:
~~~
replicate : (n : Nat) -> (x : a) -> Vect n a
~~~
The declaration can be read as, "`replicate` is a function that takes a natural number `n` and
a value `x` of some arbitrary type `a`. It returns a `Vect` of length `n`, with values of type `a`".
This is classic dependent typing: the value of a parameter to the `replicate` function is used in
defining the return type of the function.

At this point, you might reasonably assume the declaration of `replicate` works because the value of `n`
just feeds into a "parameter" of the `Vect` type rather than a completely changing the function's type.
(Technically we would call `n` an _index_ of `Vect`; the data type `a` is a _parameter_.)
But in fact, the dependent type paradigm is fully general -- it's
[turtles all the way down](https://en.wikipedia.org/wiki/Turtles_all_the_way_down).
Continuing to use functions as our example, the return type of a function can depend arbitrarily
on values of the function's parameters.

For example, the following declaration is strange but valid:
~~~
strange: (n : Nat) -> if n == 0 then Int else String
~~~
`strange` is a function of a natural number `n` that returns an `Int` of `n` is zero, and otherwise a `String`.
As a next step in seeing the flavor of Idris, here is a complete definition of a suitable `strange` function:
~~~
strange: (n : Nat) -> if n == 0 then Int else String
strange Z = 0
strange (S k) = "non-zero"
~~~
The data type `Nat` is declared in Idris' standard library to represent non-negative integers. The `Nat` type
turns out to be very useful in type signatures both because natural numbers come up frequently in the real world
(you never saw a list of -3 items, nor a list of 3.14 items), and because the `Nat` type is easy to manipulate
in ways that the Idris compiler understands. The Idris library declares two constructors for `Nat` values:
`Z` represents zero, while `S k` represents the successor of another `Nat` called `k`.

In Idris, as in Haskell and some other functional languages, a function definition can be defined for multiple
cases representing different patterns matched by the function parameters.
In this case, we have defined `strange` to return `0` for `Z`, or  else `"non-zero"` for any `S k`.
We can try this out in the Idris REPL:
~~~
*strange> strange 0
0 : Int
*strange> strange 1
"non-zero" : String
*strange>
~~~
So what type does `strange` actually have? It has exactly the type we gave it:
~~~
*strange> :type strange
strange : (n : Nat) -> if n == 0 then Int else String
~~~
As I was beginning my journey into Idris, I had a hard time getting used to unevaluated expressions (such as the
return type above) lingering at compile time as real things. From my previous 40 years of programming, I am used to
programming languages working like calculators: we can write down `x + 3` in the source code, but it just
represents the operation of adding `3` to some particular value stored in `x`. In traditional languages, we don't
manipulate `x + 3` as an expression. But in the Idris type system, we do. I have gradually gotten used to thinking
of the Idris type system as more like algebra than like a calculator. (Technically, it is closer to a [typed lambda calculus](https://en.wikipedia.org/wiki/Typed_lambda_calculus),
but that's an unnecessarily intimidating name for what's going on.)

To provide a first glimpse of the expressive power of dependent types, let's look at some more functions involving
`Vect`s. Here is the type declaration for an infix operator `++` that appends two `Vect`s:
~~~
(++) : Vect m a -> Vect n a -> Vect (m + n) a
~~~
To my eye, that is quite expressive! `++` could conceivably do something other than append its two
arguments, but just from the type declaration we'd all be shocked if it did.

Let's look for a function involving `Vect`s where the type declaration seems likely to help prevent common errors.
Here's a classic:
~~~
zip : Vect n a -> Vect n b -> Vect n (a, b)
~~~
The `zip` function is a basic operation of most functional programming: given two lists of the same length,
it produces a list of corresponding pairs. For example, in the Idris REPL:
~~~
Idris> zip [1, 2, 3] ["a", "b", "c"]
[(1, "a"), (2, "b"), (3, "c")] : List (Integer, String)
~~~

The standard libraries of different functional programming languages differ on what `zip` should do if its
input lists have different lengths. In some languages, it is a runtime error. In others, excess elements of the
longer list are silently ignored. In Idris, it is a compile-time type-checking error to try to `zip` `Vect`s
of different lengths! We can see this happen in the Idris REPL:
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
in Idris it is fairly helpful. It essentially says that type-checking of our call
to `Vect.zip` failed as it recursed down through the recursive definition of the `Vect` data type,
when it eventually tried to match a non-zero-length `Vect` type with a zero-length `Vect` type.

But around now, you are probably wondering how the Idris compiler can possibly know at compile time whether
the lengths of two `Vect`s are the same. In the REPL example above, this is easy: we provided specific `Vect`
literals like `[1, 2, 3]` and `["a", "b", "c"]`, so it makes perfect sense that the compiler knows whether
out literals have the same length. But in general?

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
zip_replicas_broken : (numAs : Nat) -> a -> (numBs : Nat) -> b -> Vect numAs (a, b)
zip_replicas_broken numAs valA numBs valB =
  let aVec = replicate numAs valA
      bVec = replicate numBs valB
  in Vect.zip aVec bVec
~~~
The Idris compiler gives an excellent error message (although we added the line breaks):
~~~
When checking right hand side of zip_replicas_broken with expected type Vect numAs (a, b)
When checking argument n to function Data.Vect.replicate:
Type mismatch between numAs (Inferred value) and numBs (Given value)
~~~

Here is an example of a similar function that does compile, because the Idris compiler can see from
how the code is written that it will not try to zip `Vect`s of different lengths:
~~~
zip_replicas : (n : Nat) -> a -> b -> Vect n (a, b)
zip_replicas n valA valB =
  let aVec = replicate n valA
      bVec = replicate n valB
  in Vect.zip aVec bVec
~~~

Here is an example of a similar function that you might wish would compile, because as a human
being you can see that the two vectors always have the same length, but that does not compile
because the Idris compiler is unconvinced:
~~~
-- This does not compile.
zip_replicas_successor_broken : (n : Nat) -> a -> b -> Vect (n + 1) (a, b)
zip_replicas_successor_broken n valA valB =
  let aVec = replicate (n + 1) valA
      bVec = valB :: replicate n valB
  in Vect.zip aVec bVec
~~~
In this case, Idris complains:
~~~
When checking right hand side of zip_replicas_successor_broken with expected type Vect (n + 1) (a, b)
Type mismatch between Vect (S n) b (Type of valB :: replicate n valB)
                  and Vect (plus n 1) b (Expected type)
Specifically: Type mismatch between S n and plus n 1
~~~
It's a great error message, but it shows the Idris compiler being a little dumb: it doesn't know that `S n`
(the successor of n) is the same as `plus n 1` (aka `n + 1`). Interestingly, the following is just barely different,
but does compile:
~~~
zip_replicas_successor : (n : Nat) -> a -> b -> Vect (1 + n) (a, b)
zip_replicas_successor n valA valB =
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
When the Idris compile sees
~~~
1 + n
~~~
it uses an interface definition in the standard library to translate
this into
~~~
plus 1 n
~~~
It translates `1` into `S Z` -- the successor of `Nat`'s zero value -- giving it
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
This is exactly what it needs to type-check `zip_replicas_successor` as defined above.

If, instead, we really like writing `n + 1` in our type signatures
(like we tried to do in `zip_replicas_successor_broken` above),
we have to give the Idris compiler a little help to see our deeper truth:
~~~
zip_replicas_successor2 : (n : Nat) -> a -> b -> Vect (n + 1) (a, b)
zip_replicas_successor2 n valA valB =
  let aVec = replicate (n + 1) valA
      bVec = valB :: replicate n valB
  in Vect.zip aVec (rewrite plusCommutative n 1 in bVec)
~~~
You may remember from high-school algebra that addition is commutative: x + y = y + x.
To get `zip_replicas_successor2` to type-check, we had to explicitly point out
the commutativity of addition to the Idris compiler. This enabled the compiler to
recognize that `bVec`'s type `Vect (S n) b` is the same as the expected type, `Vect (plus n 1) b`.

Yikes! Did the Idris compiler just force us to outline a high-school algebra proof before it would
compile our code? Why yes, that's exactly what happened.

Is this a good thing? Time will tell, as the community explores the benefits and costs
of dependent types. But it is a plausible tradeoff. Dependent types allow us to
express invariants and function contracts in type signatures. These invariants and
contracts are then enforced by the Idris compiler. Compared to traditional static typing,
this allows the compiler to catch even more of our mistakes. As we read code,
it allows us to rely on the truth of all invariants and contracts expressed in type signatures.
To gain these benefits, we have to write our Idris code in such a way that it provably adheres
to its type signatures.
