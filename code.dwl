%dw 2.0
output application/json

// 4) Add a new field to keep track of the object’s index, basing on the EndOfConnection field. 
fun getConnectionIndexPerAppliedConnection (connections: Array, index: Number) = (
    if (isEmpty(connections)) []
    else do {
        var firstConnection = connections[0]
        var restOfConnections = connections[1 to -1] default []
        var nextConnectionIndex = if (firstConnection.EndOfConnection) 1
            else index + 1
        ---
        {
            (firstConnection as Object),
            indexBasedOnEOC: index
        } >> getConnectionIndexPerAppliedConnection(restOfConnections, nextConnectionIndex)
    }
)
---
( //7)
//flatten // 3.1)
// 1) Extract the Connections arrays.
payload.FlightOptions.Connections 
// 2) Change all the EndOfConnection to true for the last Connection object.
reduce ((flightOption, accumulator=[]) -> do {
    var lastConnection = {
        (flightOption[-1] - "EndOfConnection"),
        EndOfConnection: true
    }
    var updatedConnections = if (sizeOf(flightOption) > 1) (
        flightOption[0 to -2] + lastConnection
    ) else [lastConnection]
    ---
    accumulator + updatedConnections
    // accumulator + updatedConnections 3.3)
})
// 3.2) flatten the array of arrays to be just one array.
reduce ((item, accumulator=[]) -> accumulator ++ item)
// 4) Add a new field to keep track of the object’s index, basing on the EndOfConnection field. 
getConnectionIndexPerAppliedConnection 1
// 5) Add a new field to keep track of the final AppliedConnections object’s (first) index where the object in question will be added.  
map ({
    ($),
    indexAppliedConnections: $$ + 1 - $.indexBasedOnEOC,
    //IndexValue: $$ + 1 // 9) Playing with the indexes 
})
// 6) Separate the objects based on the EndOfConnection value (true or false).
groupBy $.EndOfConnection
// 7) Take only the objects that are inside the “true” list.
)."true" as Array
// 8) Create the final output
map ((trueConnection, index) -> {
    AppliedTaxCode: trueConnection.TaxCode,
    AppliedConnections: (1 to trueConnection.indexBasedOnEOC) map {
        Type: "Connection",
        //indexBasedOnEOC: trueConnection.indexBasedOnEOC,
        //indexAppliedConnections: trueConnection.indexAppliedConnections,
        //actualNum: $,
        //actualIndex: $$+1,
        IndexValue: $ + trueConnection.indexAppliedConnections
    }
})
