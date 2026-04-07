-- A Wire holds a named value
data Wire = Wire { wireName :: String, wireValue :: Int } deriving Show

-- The only operation on wires: addition
(<+>) :: Wire -> Wire -> Wire
a <+> b = Wire
    { wireName  = wireName a ++ "+" ++ wireName b
    , wireValue = wireValue a + wireValue b
    }

infixl 6 <+>

-- The Module monad: a state monad that tracks all declared wires
newtype Module a = Module { runModule :: [Wire] -> (a, [Wire]) }

instance Functor Module where
    fmap f m = Module $ \ws ->
        let (x, ws') = runModule m ws
        in  (f x, ws')

instance Applicative Module where
    pure x = Module $ \ws -> (x, ws)
    mf <*> mx = Module $ \ws ->
        let (f, ws1) = runModule mf ws
            (x, ws2) = runModule mx ws1
        in  (f x, ws2)

instance Monad Module where
    return = pure
    m >>= f = Module $ \ws ->
        let (x, ws') = runModule m ws
        in  runModule (f x) ws'

-- Declare a wire with a name and assign it a value
wire :: String -> Int -> Module Wire
wire name val = Module $ \ws ->
    let w = Wire { wireName = name, wireValue = val }
    in  (w, ws ++ [w])

-- Run a Module and return the final Wire's value
evaluate :: Module Wire -> Int
evaluate m = wireValue result
  where
    (result, _) = runModule m []

-- Example: three wires, all added together
circuit :: Module Wire
circuit = do
    a <- wire "a" 3
    b <- wire "b" 4
    c <- wire "c" 5
    return (a <+> b <+> c)

main :: IO ()
main = print (evaluate circuit)
