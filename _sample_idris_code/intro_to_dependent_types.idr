import Data.Vect

strange : (n : Nat) -> if n == 0 then Int else String
strange Z = 0
strange (S k) = "positive"

strangeLength : (s : String) -> if length s == 0 then Int else String
strangeLength s = strange (length s)

{-
-- Doesn't compile, because Idris enforces parametricity.
replicateWithWart : (n : Nat) -> a -> Vect n a
replicateWithWart {a} n x =
  case a of
    Int => replicate n 0
    _   => replicate n x
-}

useTortured : a -> b -> (Type, a, b)
useTortured {a} {b} x y = tortured [a, b] x y

-- Doesn't compile
useTorturedBroken : a -> b -> (Type, a, b)
useTorturedBroken {a} {b} x y = tortured [a, b] x x

{-
-- Doesn't compile
useTorturedBroken : (x : a) -> (y : b) -> (Type, a, b)
useTorturedBroken {a} {b} x y = tortured [a, b] x x
-}

{-
-- Doesn't compile
strangeLengthBroken : (s : String) -> if length s == 0 then Int else String
strangeLengthBroken s = strange (length s + 1)
-}

{-
zipReplicasBroken : (numAs : Nat) -> a -> (numBs : Nat) -> b -> Vect numAs (a, b)
zipReplicasBroken numAs valA numBs valB =
  let aVec = replicate numAs valA
      bVec = replicate numBs valB
  in Vect.zip aVec bVec
-}
zipReplicas : (n : Nat) -> a -> b -> Vect n (a, b)
zipReplicas n valA valB =
  let aVec = replicate n valA
      bVec = replicate n valB
  in Vect.zip aVec bVec

{-
zipReplicasSuccessorBroken : (n : Nat) -> a -> b -> Vect (n + 1) (a, b)
zipReplicasSuccessorBroken n valA valB =
  let aVec = replicate (n + 1) valA
      bVec = valB :: replicate n valB
  in Vect.zip aVec bVec
~-}
zipReplicasSuccessor : (n : Nat) -> a -> b -> Vect (1 + n) (a, b)
zipReplicasSuccessor n valA valB =
  let aVec = replicate (1 + n) valA
      bVec = valB :: replicate n valB
  in Vect.zip aVec bVec

zipReplicasSuccessor2 : (n : Nat) -> a -> b -> Vect (n + 1) (a, b)
zipReplicasSuccessor2 n valA valB =
  let aVec = replicate (n + 1) valA
      bVec = valB :: replicate n valB
  in Vect.zip aVec (rewrite plusCommutative n 1 in bVec)
