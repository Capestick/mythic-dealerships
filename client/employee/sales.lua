local salesMenu
local salesMenuSub

local saleData = {}

AddEventHandler('Dealerships:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
    Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    Notification = exports['mythic-base']:FetchComponent('Notification')
    Menu = exports['mythic-base']:FetchComponent('Menu')
    Utils = exports['mythic-base']:FetchComponent('Utils')
end

AddEventHandler('Core:Shared:Ready', function()
    exports['mythic-base']:RequestDependencies('Dealerships', {
        'Callbacks',
        'Notification',
        'Menu',
        'Utils',
    }, function(error)
        if #error > 0 then
            return
        end
        RetrieveComponents()
    end)
end)

local loanData = {
    weeks = 10,
    downpayment = 30,
}

AddEventHandler('Dealerships:Client:OpenSales', function(hit, data)
    if data and data.dealerId then
        OpenDealershipSales(data.dealerId)
    end
end)

function OpenDealershipSales(dealerId)
    if not Callbacks then
        Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    end
    if not Notification then
        Notification = exports['mythic-base']:FetchComponent('Notification')
    end
    if not Menu then
        Menu = exports['mythic-base']:FetchComponent('Menu')
    end
    if not Utils then
        Utils = exports['mythic-base']:FetchComponent('Utils')
    end
    
    if not Callbacks or not Notification or not Menu or not Utils then
        return
    end
    
    local dealerData = _dealerships[dealerId]
    if dealerData then
        Callbacks:ServerCallback('Dealerships:Sales:FetchData', dealerId, function(authed, stocks, serverTime, defaultInterestRate, dealerMData)
            if not authed then
                Notification:Error('You\'re Not Authorized to Make Sales', 3500, 'car-building')
                return
            end
            
            -- Ensure dealerMData exists with defaults
            if not dealerMData then
                dealerMData = {
                    profitPercentage = 15,
                    commission = 25
                }
            end
            
            local stockData = FormatDealerStockToCategories(stocks)
            salesMenuSub = {}
            
            salesMenu = Menu:Create('salesMenu', string.format('View %s Stock', _dealerships[dealerId].abbreviation), function()
            
            end, function()
                salesMenu = nil
                salesMenuSub = nil
                collectgarbage()
            end)
            salesMenu.Add:Text(string.format('There are %s different models of vehicle, totalling %s vehicles', stockData.total, stockData.totalQuantity), { 'pad', 'center', 'code' })

            local orderedCategories = Utils:GetTableKeys(_catalogCategories)
            table.sort(orderedCategories, function(a, b)
                return _catalogCategories[a] < _catalogCategories[b]
            end)

            local minSaleMultiplier = 1 + ((dealerMData.profitPercentage or 10) / 100)

            for _, category in ipairs(orderedCategories) do
                if stockData.sorted[category] and #stockData.sorted[category] > 0 then
                    salesMenuSub[category] = Menu:Create('salesMenuCat-'.. category, _catalogCategories[category])
        
                    for k, v in ipairs(stockData.sorted[category]) do
                        if v.quantity > 0 then
                            local vehMenuIdentifier = string.format('c:%s:%s', category, v.vehicle)
                            local vehName = v.make .. ' ' .. v.model
                            salesMenuSub[vehMenuIdentifier] = Menu:Create('salesMenu-'.. vehMenuIdentifier, vehName)
                            salesMenuSub[vehMenuIdentifier].Add:Text(string.format(
                                [[
                                    Make & Model: %s<br>
                                    Class: %s<br>
                                    Category: %s<br>
                                    Minimum Sale Price: %s<br>
                                    Last Purchased: %s<br>
                                ]],
                                vehName,
                                v.class and string.upper(v.class) or '?',
                                _catalogCategories[v.category],
                                v.price and ('$' ..formatNumberToCurrency(math.floor(Utils:Round(v.price * minSaleMultiplier, 0)))) or '$?',
                                (v.lastPurchased and GetFormattedTimeFromSeconds(serverTime - v.lastPurchased) .. ' ago.' or 'Never')
                            ), { 'code', 'pad'})

                            local cashSaleIdentifier = vehMenuIdentifier .. '-cash-sale'
                            local loanSaleIdentifier = vehMenuIdentifier .. '-loan-sale'


                            -- Cash Sales Menu
                            salesMenuSub[cashSaleIdentifier] = Menu:Create('salesMenu-'.. cashSaleIdentifier, vehName .. ' - New Sale')
                            local saleTextElem = salesMenuSub[cashSaleIdentifier].Add:Text(VehicleSalesGetCashText(dealerMData, dealerData, v), { 'code', 'pad' })

                            salesMenuSub[cashSaleIdentifier].Add:Number('Customers State ID', {
                                current = saleData.customer
                            }, function(data)
                                saleData.customer = data.data.value
                            end)
                            salesMenuSub[cashSaleIdentifier].Add:Button('Send Sale Request', { success = true }, function()
                                if not saleData.customer then
                                    Notification:Error('Please enter the customer\'s State ID', 3000, 'car-building')
                                    return
                                end
                                
                                local customerSID = tonumber(saleData.customer)
                                if not customerSID or customerSID <= 0 then
                                    Notification:Error('Invalid State ID. Please enter a valid number.', 3000, 'car-building')
                                    return
                                end
                                
                                Callbacks:ServerCallback('Dealerships:Sales:StartSale', {
                                    dealership = dealerId,
                                    type = 'full',
                                    data = {
                                        vehicle = v.vehicle,
                                        customer = customerSID,
                                        profitPercentage = saleData.profit or dealerData.profitPercents.min,
                                    }
                                }, function(success, message)
                                    if success then
                                        Notification:Success(message or 'Sale request sent successfully', 5000, 'car-building')
                                    else
                                        Notification:Error(message or 'Failed to start sale', 5000, 'car-building')
                                    end
                                    salesMenu:Close()
                                end)
                            end)
                            --salesMenuSub[cashSaleIdentifier].Add:SubMenuBack('Go Back', {})

        

                            -- Loan Sales Menu
                            salesMenuSub[loanSaleIdentifier] = Menu:Create('salesMenu-'.. loanSaleIdentifier, vehName .. ' - New Sale')
        
                            local saleTextElem = salesMenuSub[loanSaleIdentifier].Add:Text(VehicleSalesGetLoanText(dealerMData, dealerData, v, loanData, defaultInterestRate), { 'code', 'pad' })

                            salesMenuSub[loanSaleIdentifier].Add:Slider('Down Payment %', {
                                current = loanData.downpayment,
                                min = 25,
                                max = 80,
                                step = 5,
                            }, function(data)
                                loanData.downpayment = data.data.value
                                salesMenuSub[loanSaleIdentifier].Update:Item(saleTextElem, VehicleSalesGetLoanText(dealerMData, dealerData, v, loanData, defaultInterestRate), { 'code', 'pad' })
                            end)

                            salesMenuSub[loanSaleIdentifier].Add:Slider('Loan Length (Weeks)', {
                                current = loanData.weeks,
                                min = 6,
                                max = 16,
                                step = 1,
                            }, function(data)
                                loanData.weeks = data.data.value
                                salesMenuSub[loanSaleIdentifier].Update:Item(saleTextElem, VehicleSalesGetLoanText(dealerMData, dealerData, v, loanData, defaultInterestRate), { 'code', 'pad' })
                            end)
                            salesMenuSub[loanSaleIdentifier].Add:Number('Customers State ID', {
                                current = saleData.customer
                            }, function(data)
                                saleData.customer = data.data.value
                            end)
                            salesMenuSub[loanSaleIdentifier].Add:Button('Send Sale Request', { success = true }, function()
                                if not saleData.customer then
                                    Notification:Error('Please enter the customer\'s State ID', 3000, 'car-building')
                                    return
                                end
                                
                                local customerSID = tonumber(saleData.customer)
                                if not customerSID or customerSID <= 0 then
                                    Notification:Error('Invalid State ID. Please enter a valid number.', 3000, 'car-building')
                                    return
                                end
                                
                                Callbacks:ServerCallback('Dealerships:Sales:StartSale', {
                                    dealership = dealerId,
                                    type = 'loan',
                                    data = {
                                        vehicle = v.vehicle,
                                        customer = customerSID,
                                        downPayment = loanData.downpayment,
                                        loanWeeks = loanData.weeks,
                                    }
                                }, function(success, message)
                                    if success then
                                        Notification:Success(message or 'Sale request sent successfully', 5000, 'car-building')
                                    else
                                        Notification:Error(message or 'Failed to start sale', 5000, 'car-building')
                                    end
                                    salesMenu:Close()
                                end)
                            end)
                            --salesMenuSub[loanSaleIdentifier].Add:SubMenuBack('Go Back', {})



                            salesMenuSub[vehMenuIdentifier].Add:SubMenu('Sell (As Full Payment)', salesMenuSub[cashSaleIdentifier], {})
                            salesMenuSub[vehMenuIdentifier].Add:SubMenu('Sell (As Loan)', salesMenuSub[loanSaleIdentifier], {})

                            salesMenuSub[vehMenuIdentifier].Add:SubMenuBack('Go Back', {})
                            salesMenuSub[category].Add:SubMenu(vehName, salesMenuSub[vehMenuIdentifier], {})
                        end
                    end
        
                    salesMenuSub[category].Add:SubMenuBack('Go Back', {})
                    salesMenu.Add:SubMenu(_catalogCategories[category], salesMenuSub[category], {})
                end
            end
    
            salesMenu:Show()
        end)
    end
end


function VehicleSalesGetCashText(dealerMData, dealerData, vehData)
    if not Utils then
        Utils = exports['mythic-base']:FetchComponent('Utils')
    end
    
    if not Utils then
        return ""
    end
    
    if not dealerMData then
        dealerMData = { profitPercentage = 15, commission = 25 }
    end
    local priceMultiplier = 1 + ((dealerMData.profitPercentage or 15) / 100)
    local salePrice = Utils:Round(vehData.price * priceMultiplier, 0)
    local dealerProfit = salePrice - vehData.price
    local earnedCommission = Utils:Round(dealerProfit * ((dealerMData.commission or 25) / 100), 0)

    return string.format(
        [[
            Selling Vehicle: %s %s<br>
            Customer Pays: $%s<br>
            Your Earned Commission: $%s<br>
        ]],
        vehData.make,
        vehData.model,
        formatNumberToCurrency(math.floor(salePrice)),
        formatNumberToCurrency(math.floor(earnedCommission))
    )
end

function VehicleSalesGetLoanText(dealerMData, dealerData, vehData, loanData, defaultInterest)
    if not Utils then
        Utils = exports['mythic-base']:FetchComponent('Utils')
    end
    
    if not Utils then
        return ""
    end
    
    if not dealerMData then
        dealerMData = { profitPercentage = 15, commission = 25 }
    end
    local priceMultiplier = 1 + ((dealerMData.profitPercentage or 15) / 100)
    local salePrice = Utils:Round(vehData.price * priceMultiplier, 0)
    local dealerProfit = salePrice - vehData.price
    local earnedCommission = Utils:Round(dealerProfit * ((dealerMData.commission or 25) / 100), 0)

    local downPayment = Utils:Round(salePrice * (loanData.downpayment / 100), 0)
    local salePriceAfterDown = salePrice - downPayment

    local afterInterest = Utils:Round(salePriceAfterDown * (1 + (defaultInterest / 100)), 0)
    local perWeek = Utils:Round((afterInterest / loanData.weeks), 0)

    return string.format(
        [[
            Selling Vehicle: %s %s<br>
            Loan Interest Rate: %s%%<br>
            Downpayment: %s%% ($%s)<br>
            Remaining Cost With Interest Applied: $%s<br>
            Loan Length (Weeks): %s<br>
            Weekly Payment: $%s<br>
            Your Earned Commission: $%s<br>
        ]],
        vehData.make,
        vehData.model,
        defaultInterest,
        loanData.downpayment,
        formatNumberToCurrency(math.floor(downPayment)),
        formatNumberToCurrency(math.floor(afterInterest)),
        loanData.weeks,
        formatNumberToCurrency(math.floor(perWeek)),
        formatNumberToCurrency(math.floor(earnedCommission))
    )
end