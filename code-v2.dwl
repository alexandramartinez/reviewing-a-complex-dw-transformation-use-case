%dw 2.0
output application/json 
import update from dw::util::Values // Need to import this module to use the `update` function
// Other ways to import it are:
// import * from dw::util::Values
//import dw::util::Values // if this is used, then the `update` function in the code needs to be `Values::update` instead of just `update`

// 4) Tail Recursive Function
fun addIndexTailRecursive(
    connectionsArray: Array<Object>, // current connections array (starts with all the objects, then -1, then -1, and so on until it's empty)
    indexAccumulatorArray: Array = [], // array with the indexes that are being accumulated for the `IndexValue` field. Will be empty after having a `true` EndOfConnection
    index: Number = 1, // Actual index number for each connection being evaluated. Will always have +1
    connectionsAccumulatorArray: Array = [] // array that will keep the transformed objects (final output) - this is what makes our function a tail function and not just a recursive function
) = (
    if (isEmpty(connectionsArray)) connectionsAccumulatorArray // add the condition to break the recursion. In this case, once the `connectionsArray` is empty, that means we iterated through all of the connections
    else do { // `do` is used to create local variables inside the `else`. Remember to add {} and not ()
        var thisConnection: Object = connectionsArray[0] // first object is THIS object
        var thisConnectionIsEndOfConnection: Boolean = thisConnection.EndOfConnection ~= true // use ~= to get rid of warnings, or manually coerce using `as Boolean`
        var newIndexAccumulatorArray = if (thisConnectionIsEndOfConnection) [] else indexAccumulatorArray + index // if this EndOfConnection is true, next indexAccumulatorArray should be empty. Otherwise, this connection's index should be added to the array for the next iteration
        ---
        addIndexTailRecursive( // calling the next iteration
            connectionsArray[1 to -1] default [], // need to add the `default` to make sure that `null` cases don't fail
            newIndexAccumulatorArray,
            index + 1, // index will always be +1, no matter the case
            if (thisConnectionIsEndOfConnection) ( // if this connection is `true`, then we output the new object structure
                connectionsAccumulatorArray + { // add the new object to the array accumulator
                        AppliedTaxCode: thisConnection.TaxCode,
                        AppliedConnections: (indexAccumulatorArray + index) map { // count all of the indexes from the `indexAccumulatorArray` and this connection's index too
                            Type: "Connection",
                            IndexValue: $
                        }
                    }
            )
            else connectionsAccumulatorArray // if this connection is `false` then just pass the already existing array
        )
    }
)
---
addIndexTailRecursive( // 4) Once we get the desired array of objects, call the function
    // 1) Extract the Connections arrays
    payload.FlightOptions.Connections
    // 2) Change all the EndOfConnection to true for the last Connection object from the Connections array
    reduce ((flightOption, accumulator = []) -> do { // `accumulator` needs to be set as an empty array
        var lastConnection = { // Object Destructor is applied when using {()}
            (flightOption[-1] update "EndOfConnection" with true)
        }
        // to use local variables, use the `do` keyword, followed by {}
        var updatedConnections = (flightOption[0 to -2] default []) + lastConnection
        ---
        accumulator ++ updatedConnections // 3) use ++ function to flatten within the `reduce`.
        // `flatten` function can also be used, but then we'd end up with addIndexTailRecursive(flatten(payload...
        // and this would add additional steps. If performance is not an issue, then use `flatten` and change the `++` function into the `+` operator to append arrays.
    })
)


/* EXAMPLE OF RECURSIVE FUNCTION (Not Tail)
    fun sum(number: Number) = 
    if (number > 0) 
        number + sum(number - 1)
    else 0
    // sum(254) works but sum(255) fails
*/

/* SCRIPT TO GENERATE ANY NUMBER OF CONNECTIONS FOR TESTING PURPOSES (To make sure that StackOverflow error doesn't appear)
    {
        FlightOptions: [
            {
                Connections: (0 to 300) map {
                    ReferenceID: $$,
                    TaxCode: "ABC" ++ ($$ as String),
                    EndOfConnection: (random() * 100) > 52
                }
            }
        ]
    }
*/
