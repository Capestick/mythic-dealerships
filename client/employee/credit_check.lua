AddEventHandler('Dealerships:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
    Input = exports['mythic-base']:FetchComponent('Input')
    Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    Confirm = exports['mythic-base']:FetchComponent('Confirm')
    Utils = exports['mythic-base']:FetchComponent('Utils')
end

AddEventHandler('Core:Shared:Ready', function()
    exports['mythic-base']:RequestDependencies('Dealerships', {
        'Input',
        'Callbacks',
        'Confirm',
        'Utils',
    }, function(error)
        if #error > 0 then
            return
        end
        RetrieveComponents()
    end)
end)

AddEventHandler('Dealerships:Client:StartRunningCredit', function(hit, data)
    if not Input then
        Input = exports['mythic-base']:FetchComponent('Input')
    end
    
    if not Input then
        return
    end
    
    Input:Show(
        "Run Credit Check & See Max Borrowable Amount",
        "Customer State ID",
        {
            {
                id = 'SID',
                type = 'number',
                options = {
                    inputProps = {
                        maxLength = 4,
                    },
                }
            },
        },
        "Dealerships:Client:RecieveInput",
        data
    )
end)

AddEventHandler('Dealerships:Client:RecieveInput', function(values, data)
    if not Callbacks then
        Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    end
    if not Confirm then
        Confirm = exports['mythic-base']:FetchComponent('Confirm')
    end
    if not Utils then
        Utils = exports['mythic-base']:FetchComponent('Utils')
    end
    
    if not Callbacks or not Confirm or not Utils then
        return
    end
    
    if not values or not values.SID then
        Confirm:Show(
            'Credit Check Results',
            {},
            [[
                Please enter a valid State ID.
            ]],
            {},
            'Close',
            'Ok'
        )
        return
    end
    
    local sid = tonumber(values.SID)
    if not sid or sid <= 0 then
        Confirm:Show(
            'Credit Check Results',
            {},
            [[
                Invalid State ID. Please enter a valid number.
            ]],
            {},
            'Close',
            'Ok'
        )
        return
    end
    
    Callbacks:ServerCallback('Dealerships:CheckPersonsCredit', {
        dealerId = data.dealerId,
        SID = sid,
    }, function(response)
        if not response then
            Confirm:Show(
                'Credit Check Results',
                {},
                [[
                    An error occured whilst running credit.
                ]],
                {},
                'Close',
                'Ok'
            )
            return
        end
        
        local price = response.price
        local score = response.score or 0
        local canBorrow = price and price ~= false and type(price) == "number"
        
        if canBorrow then
            Confirm:Show(
                'Credit Check Results',
                {},
                string.format(
                    [[
                        State ID %s is elegible for a vehicle loan of <b>$%s</b> with their current credit score
                        of %s.
                    ]],
                    values.SID,
                    formatNumberToCurrency(math.floor(Utils:Round(price or 0, 0))),
                    score
                ),
                {},
                'Close',
                'Ok'
            )
        else
            if score and price == false then
                Confirm:Show(
                    'Credit Check Results',
                    {},
                    string.format(
                        [[
                            State ID %s is not elegible for a vehicle loan. This is because they already have an active vehicle loan. At this time people can 
                            only have a single vehicle loan.
                        ]],
                        values.SID
                    ),
                    {},
                    'Close',
                    'Ok'
                )
            elseif score then
                Confirm:Show(
                    'Credit Check Results',
                    {},
                    string.format(
                        [[
                            State ID %s is not elegible for a vehicle loan with their current credit score of %s.
                        ]],
                        values.SID,
                        score
                    ),
                    {},
                    'Close',
                    'Ok'
                )
            else
                Confirm:Show(
                    'Credit Check Results',
                    {},
                    [[
                        An error occured whilst running credit.
                    ]],
                    {},
                    'Close',
                    'Ok'
                )
            end
        end
    end)
end)