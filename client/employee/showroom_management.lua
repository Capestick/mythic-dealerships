local showroomManagement
local showroomManagementSub

AddEventHandler('Dealerships:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
    Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    Notification = exports['mythic-base']:FetchComponent('Notification')
    Menu = exports['mythic-base']:FetchComponent('Menu')
    Utils = exports['mythic-base']:FetchComponent('Utils')
    Game = exports['mythic-base']:FetchComponent('Game')
    Vehicles = exports['mythic-base']:FetchComponent('Vehicles')
end

AddEventHandler('Core:Shared:Ready', function()
    exports['mythic-base']:RequestDependencies('Dealerships', {
        'Callbacks',
        'Notification',
        'Menu',
        'Utils',
        'Game',
        'Vehicles',
    }, function(error)
        if #error > 0 then
            return
        end
        RetrieveComponents()
    end)
end)

AddEventHandler('Dealerships:Client:ShowroomManagement', function(hit, data)
    if data and data.dealerId then
        OpenShowroomManagement(data.dealerId)
    end
end)

function OpenShowroomManagement(dealerId)
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
    
    if _dealerships[dealerId] and #_dealerships[dealerId].showroom > 0 then
        Callbacks:ServerCallback('Dealerships:ShowroomManagement:FetchData', dealerId, function(authed, stocks)
            local stockData = FormatDealerStockToCategories(stocks)
            
            if not authed then
                Notification:Error('You\'re Not Authorized to Open Showroom Management')
                return
            end

            showroomManagementSub = {}
            showroomManagement = Menu:Create('showroomManagement', string.format('Manage %s Showroom', _dealerships[dealerId].abbreviation), function()
            
            end, function()
                showroomManagement = nil
                showroomManagementSub = nil
                collectgarbage()
            end)

            for pos = 1, #_dealerships[dealerId].showroom do
                local posVehicle = GlobalState.DealershipShowrooms[dealerId] and GlobalState.DealershipShowrooms[dealerId][tostring(pos)]
                showroomManagement.Add:AdvButton(posVehicle and string.format('%s %s', posVehicle.make and posVehicle.make or 'Unknown', posVehicle.model and posVehicle.model or 'Unknown') or 'No Vehicle', { secondaryLabel = '#'.. pos}, function()
                    showroomManagement:Close()
                    Wait(100)
                    StartSettingShowroomPosition(stockData, dealerId, pos, posVehicle)
                end)
            end

            showroomManagement:Show()
        end)
    end
end

function StartSettingShowroomPosition(stockData, dealerId, position, positionVehicle)
    if not Menu then
        Menu = exports['mythic-base']:FetchComponent('Menu')
    end
    if not Callbacks then
        Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    end
    if not Notification then
        Notification = exports['mythic-base']:FetchComponent('Notification')
    end
    if not Utils then
        Utils = exports['mythic-base']:FetchComponent('Utils')
    end
    
    if not Menu or not Callbacks or not Notification or not Utils then
        return
    end
    
    showroomManagement = Menu:Create('showroomManagement', string.format('Setting %s Showroom Position #%s', _dealerships[dealerId].abbreviation, position), function()
    
    end, function()
        showroomManagement = nil
        showroomManagementSub = nil
        collectgarbage()
    end)

    showroomManagementSub = {}

    if positionVehicle then
        showroomManagement.Add:SubMenuBack('Clear Current Vehicle', {}, function()
            Wait(50)
            Callbacks:ServerCallback('Dealerships:ShowroomManagement:SetPosition', {
                dealerId = dealerId,
                position = position,
                vehData = false,
            }, function(success)
                if success then
                    Notification:Success('Successfully Cleared Vehicle in Position #'.. position)
                else
                    Notification:Error('Failed to Clear Vehicle in Position #'.. position)
                end
                OpenShowroomManagement(dealerId)
            end)
        end)
    end

    local orderedCategories = Utils:GetTableKeys(_catalogCategories)
    table.sort(orderedCategories, function(a, b)
        return _catalogCategories[a] < _catalogCategories[b]
    end)

    showroomManagement.Add:Text('Set Position #' .. position .. ' Vehicle', { 'heading', 'center' })

    for _, category in ipairs(orderedCategories) do
        if stockData.sorted[category] and #stockData.sorted[category] > 0 then
            showroomManagementSub[category] = Menu:Create('showroomManagementCat-'.. category, _catalogCategories[category])

            for k, v in ipairs(stockData.sorted[category]) do
                showroomManagementSub[category].Add:AdvButton(('%s %s'):format(v.make, v.model), { secondaryLabel = (v.class or 'Unknown') .. ' Class' }, function()
                    Wait(100)
                    showroomManagement:Close()
                    SetDealerShowroomVehicleAtPosition(dealerId, position, v)
                end)
            end

            showroomManagementSub[category].Add:SubMenuBack('Go Back', {})

            showroomManagement.Add:SubMenu(_catalogCategories[category], showroomManagementSub[category], {})
        end
    end

    showroomManagement.Add:SubMenuBack('Go Back', {}, function()
        Wait(50)
        OpenShowroomManagement(dealerId)
    end)

    showroomManagement:Show()
end

function SetDealerShowroomVehicleAtPosition(dealerId, position, vehData)
    if not Game then
        Game = exports['mythic-base']:FetchComponent('Game')
    end
    if not Vehicles then
        Vehicles = exports['mythic-base']:FetchComponent('Vehicles')
    end
    if not Callbacks then
        Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    end
    if not Notification then
        Notification = exports['mythic-base']:FetchComponent('Notification')
    end
    
    if not Game or not Vehicles or not Callbacks or not Notification then
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    Game.Vehicles:SpawnLocal(vector3(playerCoords.x, playerCoords.y, playerCoords.z - 20.0), vehData.vehicle, 100, function(vehicle)
        FreezeEntityPosition(vehicle, true)
        local vehProperties = Vehicles.Properties:Get(vehicle)
        Game.Vehicles:Delete(vehicle)

        Callbacks:ServerCallback('Dealerships:ShowroomManagement:SetPosition', {
            dealerId = dealerId,
            position = position,
            vehData = {
                vehicle = vehData.vehicle,
                make = vehData.make,
                model = vehData.model,
                class = vehData.class,
                category = vehData.category,
                properties = vehProperties,
            },
        }, function(success)
            if success then
                Notification:Success('Successfully Updated Vehicle in Position #'.. position)
            else
                Notification:Error('Failed to Update Vehicle in Position #'.. position)
            end
            OpenShowroomManagement(dealerId)
        end)
    end)
end