strange: (n : Nat) -> if n == 0 then Int else String
strange Z = 0
strange (S k) = "non-zero"
