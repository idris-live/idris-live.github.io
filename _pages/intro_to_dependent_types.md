---
permalink: /understanding_dependent_types
---

# Introduction to Dependent Types

Updated October 3, 2016
{: .small}

This tutorial provides an overview of dependent types in Idris. It doesn't assume any prior knowledge of
dependent types or Idris, and it tries to progress gently from the basics to a modest depth.
It can be used as a first look at Idris, or as supplemental reading to the [Dependent Types](http://docs.idris-lang.org/en/latest/tutorial/typesfuns.html#dependent-types)
section of the official [Idris Tutorial](http://docs.idris-lang.org/en/latest/tutorial/).

**Work in progress!** This tutorial has not yet been reviewed by the Idris community. The lead author, Dean,
is still new to Idris. See **Participating** in the left sidebar. There is a [discussion thread](https://groups.google.com/forum/#!topic/idris-lang/a5SdUl9W0KY) about this
tutorial in the Idris Google group.
{: .notice--warning}

## Definition

A dependent type is computed from one or more values. Many programming languages support generic types that
take other types as parameters. A dependent type goes a large step further: it can be computed from arbitrary values, such as integers, strings, database schemas, or any other data structures you define in your own code.

## Simple Examples

Introductions to dependent types often use the example `Vect n a`, which represents a list of `n` values of type `a`.
`Vect` is a type constructor -- a function that takes `n` and `a` as arguments and constructs a type.
For example, `Vect 3 String` is a list of 3 strings. (In Idris, like Haskell, the syntax for function application
does not require parentheses.)

One way to create a `Vect` is to use the `replicate` function defined in the Idris standard library:

~~~
replicate : (n : Nat) -> (x : a) -> Vect n a
~~~

The declaration can be read as follows: "`replicate` is a function that takes a natural number `n` and
a value `x` of some arbitrary type `a`. It returns a `Vect` of length `n` having values of type `a`".
This nicely illustrates the nature of a dependent type: the return type of `replicate` depends
on the value of one of `replicate`'s arguments.

From the name `replicate` and the type signature, it is easy to guess correctly that the `Vect`
returned by `replicate` consists of the value `x` repeated `n` times.
In fact, as we will see shortly, this is the only possible behavior of `replicate` given its type signature.

You might reasonably imagine that the dependency of `replicate`'s return type on its argument `n`
works because the value of `n` is only used as an argument to the `Vect` return type,
rather than completely changing the return type.
But in fact, the dependent type paradigm is fully general -- it's
[turtles all the way down](https://en.wikipedia.org/wiki/Turtles_all_the_way_down).
In Idris, types are first-class entities that can be computed and manipulated just like any other value.
The return type of an Idris function can be freely calculated from the values of its arguments.

The following declaration,
for example, is strange but valid:

~~~
strange: (n : Nat) -> if n == 0 then Int else String
~~~

This declares `strange` as a function of a natural number `n`. If `n` is zero then it returns an `Int`.
Otherwise, it returns a `String`. The appearance of `if`/`then`/`else` in this type signature isn't a special case -- any expression is legal for
computing the return type.
Types and values aren't syntactically separate; they can be freely mixed.

Here is the complete definition of `strange`:

~~~
strange : (n : Nat) -> if n == 0 then Int else String
strange Z = 0
strange (S k) = "positive"
~~~

__Note:__ The sample code for this tutorial is in GitHub, in
[intro_to_dependent_types.idr](https://github.com/idris-live/idris-live.github.io/blob/master/_sample_idris_code/intro_to_dependent_types.idr).
{: .notice--info}

The data type `Nat` is declared in Idris' standard library to represent non-negative integers. The `Nat` type
turns out to be very useful in type signatures. Partly this is because natural numbers come up frequently
in the real world -- you never saw a list of -3 items, nor a list of 3.14 items. Also, it is because the `Nat` type
is easy to manipulate in ways that the Idris compiler understands. The Idris library declares two constructors
for `Nat` values: `Z` represents zero, while `S k` represents the successor of some other `Nat` called `k`.

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

Notice that even though `Nat` is defined in terms of `Z` and `S k`, the Idris compiler understands the relationship
of this type to decimal numeric literals. In fact, its understanding goes deeper than that: it is smart enough
to represent `Nat` as an integer at runtime.

Demonstrating `strange` in the REPL may give you the impression that you are seeing some form of dynamic typing.
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

## Parametricity

Earlier, we said that `replicate`'s behavior is the only possible behavior for its type signature:

~~~
replicate : (n : Nat) -> (x : a) -> Vect n a
~~~

If `replicate` terminates without raising an exception, it must return a `Vect` containing the value `x` repeated
`n` times. The reason is that Idris deliberately defines types to be opaque values at runtime. We will
see below that a function _can_ access a type parameter (like `a` in `replicate`) at runtime, but because
type values are opaque, a function's runtime flow of control cannot depend on a type parameter.

Since `a` could be any type whatsoever, and since `replicate` cannot change its flow of control by
examining `a` (for example, it cannot say `if a == Int`), the only value of type `a`
that `replicate` could possibly use when constructing its return value is the value `x` that it is given.

This characteristic of Idris and some other languages is called
[parametricity](https://en.wikipedia.org/wiki/Parametricity). It helps both programmers and
compilers reason about type-parameterized code, by ensuring that functions which appear generic in their
type signatures don't internally special-case their parameter types. This is in contrast to a language like
Java, where operations like `.class` and `instanceof` allow dependencies on representation types
to leak across abstraction boundaries. It's a matter of taste whether parametricity is delightfully pure
or annoyingly restrictive, but it certainly has benefits.

## The Expressive Power of Dependent Types

To provide a first glimpse of the expressive power of dependent types, let's look at more functions involving
`Vect`s. Here is the declaration of an infix operator `++` that appends two `Vect`s:

~~~
(++) : Vect m a -> Vect n a -> Vect (m + n) a
~~~

This declares `++` as an operator that takes two arguments (ignoring
_currying_ for now): a `Vect` of `m` values of type `a` and another
`Vect` of `n` values of the same type. It declares `++` to return
a `Vect` of `m + n` values of that type. (Argument names are optional
in Idris function type signatures; they are omitted in this declaration.)

The declaration of `++` is quite expressive! This operator could conceivably do something other than append its two arguments,
but just from the type signature we'd be shocked if that wasn't what it did.

Let's look for a function involving `Vect`s where the type declaration may help prevent likely mistakes.
Here's a classic:

~~~
zip : Vect n a -> Vect n b -> Vect n (a, b)
~~~

The `zip` function is a basic operation of most functional programming. Given two lists of the same length,
it produces a list of corresponding pairs. Each pair is respresented as a _tuple_. A tuple is similar to a `Vect`,
except that each element of a tuple has its own, declared type as we see here.

For example, in the Idris REPL:

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

The answer is that when a type signature enforces a constraint involving runtime values, the Idris compiler tries to prove to itself that
the constraint is always met.
This places an obligation on the Idris programmer to write the code in a way supports such a proof.
Sometimes, as in the example above that zips two literal `Vect`s, this is
very easy. Sometimes it is very difficult. As a community, we will have to learn when the benefits of
enforcing more constraints at compile-time are worth the extra effort of supporting the compiler's proof that the
constraints are met.

Here is an example of a function using `zip` that type-checks, because the Idris compiler can see from
how the code is written that it will not try to zip `Vect`s of different lengths:

~~~
zipReplicas : (n : Nat) -> a -> b -> Vect n (a, b)
zipReplicas n valA valB =
  let aVec = replicate n valA
      bVec = replicate n valB
  in Vect.zip aVec bVec
~~~

Here is an example of a similar function that does _not_ compile, because the Idris compiler correctly sees
that it may try to `Vect.zip` two lists of different lengths:

~~~
-- Doesn't compile
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

## Runtime Versus Compile Time

In the Idris REPL, let's examine the type of the `strange` example function
that we defined earlier:

~~~
*strange> :type strange
strange : (n : Nat) -> if n == 0 then Int else String
~~~

Early in one's journey into Idris, it may seem odd that unevaluated expressions (such as
`if n == 0 then Int else String` in the return type of `strange`, above)
linger at compile time as real things. Most programming languages
work more like calculators: if we write down `x + 1` in the source code, we mean that
when control flow reaches that point, `x` will have some particular value and the code should
compute that value plus one.

The Idris type system works like algebra: instead of just translating
an expression like `x + 1` into runtime code that will add one, it often understands a more general,
contextual meaning of the expression. For example, the Idris compiler may recognize in context
that `x + 1` means "`x + 1` for all `x`", or "`x + 1` for whatever `x` is passed as an argument to this function".

Dependently typed languages like Idris draw the line between runtime and compile time differently than most of us
have experienced before. We find ourselves looking at Idris code trying to understand how what seems to be happening
could possibly be happening. In [Edwin Brady's book](https://www.manning.com/books/type-driven-development-with-idris),
he gives the example of an "Interactive Data Store" -- a small program that interacts with the user through the
stdin/stdout console. It allows the user to interactively define a simple data schema and then enter and retrieve
information that matches this schema. The example's source code defines a `Schema` type to capture the schema
defined through user interaction. It computes native Idris types from `Schema` instances. Then it uses these
native Idris types in compile-time type checking. How is such a thing even possible?

The good news is that, as Idris programmers, we usually don't need to worry about how this magic happens.
We write Idris code that appears to use runtime data to compute types that are used in
compile-time type checking. It is straightforward to understand what this code means,
but more difficult to understand
how it is implemented by the Idris compiler. Most of the time, we just focus on the meaning and leave the rest to the compiler.

But it is helpful to have some understanding of what happens under the covers, for all the usual reasons:
it helps build our intuition for Idris semantics; it helps us when things don't work as we expect;
and it helps us optimize Idris performance. So let's go ahead and take a quick look at what the Idris
compiler is doing.

During compile-time type checking, the Idris compiler traces control flow and data flow through our code.
It manipulates expressions involving both types and values, trying to prove to itself
that the type constraints are always met. Sometimes we have to help the compiler with these proofs
by adding code that explicitly changes the type-checking context. (We will see an example
near the end of this tutorial.)

When we write Idris code that computes types, we often write that code as though it will execute at runtime.
However, computing specific types at runtime never serves any purpose, for two reasons:

1. All Idris type-checking is performed at compile time.

2. Although types (such as Nat or String) can be manipulated in our code as though they are values,
they are opaque -- as discussed in the _Parametricity_ section earlier, the Idris language is carefully
designed not to give us any operations that would let us distinguish between two types at runtime.

The Idris compiler tries to be smart enough to avoid generating runtime code for any computations that
won't affect the runtime result. This includes omitting runtime computation of specific types. As a result,
Idris idioms which look expensive at first glance, because they perform relatively expensive calculations
for type-checking, often add little or no runtime overhead.

Curiously, type computations are often not performed at compile time either, at least not literally as
our source code would suggest. It is often more illuminating to say the Idris compiler _reasons about_
our type computations than to say it _performs_ them.
The algebra analogy is helpful in making this statement less mysterious.
If we do a bit of algebra to convince ourself that `x * (y + 1) = x * y + x`,
we don't actually add one to anything or use our mental multiplication tables.
Rather, we reason about addition and multiplication by manipulating these expressions in ways we know are sound.

We can go even further in using the algebra analogy to better understand what the Idris compiler
does during type-checking. When we do algebra, we often perform some
computations and reason about others. Consider `x * (y + 2 - 1) = x * y + x`.
In this case, we reason that `y + 2 - 1` is the same as `y + (2 - 1)`. Then, since `2` and `1` are
known values, we compute `2 - 1 = 1`, giving us `x * (y + 1) = x * y + x`. From this point forward,
every operation involves unknowns, so we reason about the operations instead of performing them.

Many of these points are illustrated by the following simple, yet tortured example:

~~~
tortured : (tv : Vect 2 Type) -> head tv -> last tv -> (Type, head tv, last tv)
tortured tv x y = (head tv, x, y)
~~~

`tortured` is a function of three arguments:

* a 2-element vector of `Type`s, named `tv`. Types like `Int` and `String` are of type `Type`,
so an example of a possible `tv` value would be `[Int, String]`.
* a value whose type is specified by the _first_ element of `tv`
* a value whose type is specified by the _last_ element of `tv`

(Readers who are uncomfortable with the statement that `tortured` has three arguments know
more about _currying_ than we are assuming for this tutorial.)

We had to give `tv` a name in the type signature, because the types of other arguments
and the return type depend on it. However, we chose not to give names to the second
and third arguments.

The syntax `-> (Type, head tv, last tv)` indicates that `tortured` returns a three-element tuple,
which contains a `Type` and two values having the types provided by `tv`.

Here is an example of a correct use of `tortured` that compiles:

~~~
useTortured : a -> b -> (Type, a, b)
useTortured {a} {b} x y = tortured [a, b] x y
~~~

Identifiers in function type signatures that start with a lower-case letter, that aren't used in a function position
(e.g. not like the `f` in `f arg`), and that aren't specifically declared, become implicit arguments to the function.
Since `a` and `b` in the above declaration meet these requirements and are used as argument types, they are implicit
type arguments to the function. The curly braces around `{a}` and `{b}` in the definition of `useTortured`
bring those implicit type arguments into scope in the function body, so that we can use them in the call to `tortured`.

If we change the final `y` in `useTortured` to a `x`, representing a plausible mistake, it no longer compiles:

~~~
-- Doesn't compile
useTorturedBroken : a -> b -> (Type, a, b)
useTorturedBroken {a} {b} x y = tortured [a, b] x x
~~~

Looking back at `useTortured`, let's try to guess what the Idris compiler will do at compile time and what
runtime code it will generate. When `useTortured` calls `tortured`, it appears to construct a `Vect 2 Type` by evaluating
the expression `[a, b]`. That `Vect` serves three purposes:

1. It provides the types that will be used to type-check the call to `tortured` from `useTortured`.

2. It provides the types that will be used to type-check the tuple expression `(head tv, x, y)` in `tortured`.

3. At runtime, it provides the `Type` value passed as `head tv` into that tuple expression.

Will the Idris compiler generate runtime code that constructs a `Vect 2 Type` value?
There is actually no reason to. Purposes 1 and 2 are compile-time type checking, so runtime is too late to matter.
For purpose 3, the code certainly appears to evaluate `head tv` to obtain a `Type` value to use in the tuple.
However, because `Type` values are opaque and cannot affect runtime flow of control,
any placeholder `Type` value would do just as well.
So presumably the `Vect 2 Type` doesn't exist at all at runtime.

Does that mean the `Vect 2 Type` is constructed at compile time? Let's consider each of the three
purposes listed above:

1. For type-checking the call to `tortured` from `useTortured`, the Idris compiler must
prove to itself that the type of `x` is `head [a, b]`. It knows from the declaration of `useTortured`
that the type of `x` is `a`, so it is left with proving to itself that `head [a, b]` is `a`. The natural
way to do this is to expand the call to `head` and then simplify the resulting expression. This is more
like doing algebra on `head [a, b]` than like interpreting it -- it is difficult to see how literally evaluating
`[a, b]` would help. Nor is there any specific `Vect 2 Type` to construct, since `a` and `b` are unknown types.
(The same line of reasoning applies to type-checking `y`.)

2. For type-checking the tuple expression `(head tv, x, y)` in `tortured`, the Idris compiler must
prove to itself that `x` has the type `head tv` and `y` has the type `last tv`. But these are immediately evident
in the type signature of `tortured`.

3. We already saw that, at runtime, any placeholder `Type` value could serve as the first value of
the tuple returned by `tortured`. The compiler certainly has no reason to construct a `Vect 2 Type` for generating a placeholder.

Bottom line: even though the code for `useTortured` appears to construct a `Vect 2 Type`, that `Vect` never
actually exists: it is neither useful at runtime nor at compile time. It is notional; it supports a line of
reasoning that we follow when we write the code, and that the Idris compiler follows when it type-checks the code.

## How Dependent Types Lead to Proofs

Earlier, we showed an example function `zipReplicas`:

~~~
zipReplicas : (n : Nat) -> a -> b -> Vect n (a, b)
zipReplicas n valA valB =
  let aVec = replicate n valA
      bVec = replicate n valB
  in Vect.zip aVec bVec
~~~

Here is an example of a similar function that we might wish would compile, because from a human perspective
we see that the two `Vect`s being `zip`ped always have the same length. However, it does not compile,
because the Idris compiler is unconvinced.

~~~
-- This does not compile.
zipReplicasSuccessorBroken : (n : Nat) -> a -> b -> Vect (n + 1) (a, b)
zipReplicasSuccessorBroken n valA valB =
  let aVec = replicate (n + 1) valA
      bVec = valB :: replicate n valB
  in Vect.zip aVec bVec
~~~

The operation `::` prepends `valB` to the front of `replicate n valB`.

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
rest of my life trying to second-guess a stupid compiler? To some degree, the answer is surely yes.
However, with a little more fluency this particular example becomes easy.

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

(The keyword `total` declares that `plus` will terminate in finite time with no exception for all inputs.
This is is important for functions used at compile time. Declaring the function `total` asks the Idris compiler to verify that it is.)

Notice that the documentation comment for `plus` does spell out that the function
splits its cases on the first argument. This tips off an experienced Idris reader
that the compiler will more easily reason about `1 + n` than about `n + 1`.

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

So, in `zipReplicasSuccessor`, the Idris compiler needs `bVec` to have the type `Vect (S n) (a, b)`. `bVec` is defined as `valB :: replicate n valB`, and the `::` operator
has the following type signature:

~~~
(::) : (x : a) -> (xs : Vect k a) -> Vect (S k) a
~~~

So it type-checks. Qed.

A more subtle reason to throw up our hands in frustration might be that our code just depended on
the _implementation_ of `plus`! If `plus` were redefined with its case-split and its recursion on the right-hand
argument instead of the left-hand argument, with no change to its type signature, our code would break. Doesn't that horribly violate
encapsulation?

No, this does not violate encapsulation. The reason we can depend on the implementation of `plus` is that it is explicitly declared as `public export`.
This deliberately makes the entire definition of `plus` transparent so the Idris type system can do algebra on it. (You can't see
this in the definition of `plus` above because `public export` is declared as the default visibility for the
[whole file](https://github.com/idris-lang/Idris-dev/blob/master/libs/prelude/Prelude/Nat.idr) in which `plus` is defined.)
If `plus` were instead just declared `export`, then uses of `plus` could only depend on its
type signature.

Now that we understand how the version of `zipReplicasSuccessor` with `1 + n` in the type signature worked,
let's ask another question: is there a way to make `n + 1` work instead? The answer is yes, but
we have to give the Idris compiler a little help to see our deeper truth.

You may remember from high-school algebra that addition is commutative: x + y = y + x.
In fact, if you felt frustrated with the Idris compiler when `n + 1` didn't work but `1 + n` did, it is probably because
you have so deeply internalized that fact. But the Idris type-checker only has certain axioms hardwired in, and commutativity of addition isn't one of them.
Nor will it automatically go prove that for itself.

To get `n + 1` to work in the type signature, we have to explicitly provide a
proof of the commutativity of addition to the Idris compiler. Fortunately, the
Idris standard library provides proofs of many simple theorems that help in this kind of type-checking situation. In this case, we use `plusCommutative` from the standard library:

~~~
zipReplicasSuccessor2 : (n : Nat) -> a -> b -> Vect (n + 1) (a, b)
zipReplicasSuccessor2 n valA valB =
  let aVec = replicate (n + 1) valA
      bVec = valB :: replicate n valB
  in Vect.zip aVec (rewrite plusCommutative n 1 in bVec)
~~~

Yikes! Did the Idris compiler just force us to provide a high-school algebra proof
before it would compile our code? Yes, that's exactly what happened.

Is this a good thing? Time will tell, as the community explores the benefits and costs
of dependent types. But it is a plausible tradeoff. Dependent types allow us to
express invariants and function contracts in type signatures. We have to write our code
in such a way that the Idris compiler can prove to itself that these constraints are always met.
In return, when we read the code, we can rely on these constraints.

Dependent types take a large additional step in the direction of two arguments commonly made for static types:

* Since any given line of code is read and reasoned about far more often then it is modified,
  it is worth some extra time to express useful machine-verified invariants.

* We don't have to unit test what the compiler will verify.

Probably some of us will end up loving these characteristics of dependent types and others will end up hating them.
But if you enjoy the solid footing that you get from traditional static types,
you may want to give dependent types a chance.
