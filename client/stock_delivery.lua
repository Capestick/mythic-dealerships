local _activeDelivery = nil
local _deliveryBlips = {}
local _waitingForTrailerPickup = false
local _waitingForUnload = false
local _processingPickup = false
local _processingUnload = false
local _trailerEntity = nil
local _truckEntity = nil

AddEventHandler('Dealerships:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
    Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    Notification = exports['mythic-base']:FetchComponent('Notification')
    Menu = exports['mythic-base']:FetchComponent('Menu')
    Blips = exports['mythic-base']:FetchComponent('Blips')
    Action = exports['mythic-base']:FetchComponent('Action')
end

AddEventHandler('Core:Shared:Ready', function()
    exports['mythic-base']:RequestDependencies('Dealerships', {
        'Callbacks',
        'Notification',
        'Menu',
        'Blips',
        'Action',
    }, function(error)
        if #error > 0 then
            return
        end
        RetrieveComponents()
    end)
end)

AddEventHandler('Dealerships:Client:StockDelivery:OpenMenu', function(hit, data)
    if data and data.dealerId then
        OpenStockDeliveryMenu(data.dealerId)
    end
end)


function OpenStockDeliveryMenu(dealerId)
    if not Callbacks then
        Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    end
    if not Notification then
        Notification = exports['mythic-base']:FetchComponent('Notification')
    end
    if not Menu then
        Menu = exports['mythic-base']:FetchComponent('Menu')
    end
    
    if not Callbacks or not Notification or not Menu then
        return
    end
    
    Callbacks:ServerCallback('Dealerships:StockDelivery:GetVehicles', { dealerId = dealerId }, function(vehicles)
        if not vehicles or #vehicles == 0 then
            Notification:Error('No vehicles defined for this dealership', 5000, 'car-building')
            return
        end

        local stockMenu = Menu:Create('stockDelivery', 'Stock Delivery', function()
        end, function()
            stockMenu = nil
            collectgarbage()
        end)

        stockMenu.Add:Text('Select a vehicle to stock up (1 stock per delivery):', { 'pad', 'center' })

        for _, veh in ipairs(vehicles) do
            stockMenu.Add:Button(string.format('%s %s (Stock: %d)', veh.make, veh.model, veh.currentStock), {}, function()
                stockMenu:Close()
                
                StartStockDelivery(dealerId, veh.vehicle)
            end)
        end

        stockMenu:Show()
    end)
end


function StartStockDelivery(dealerId, vehicle)
    if not Callbacks then
        Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    end
    if not Notification then
        Notification = exports['mythic-base']:FetchComponent('Notification')
    end
    
    if not Callbacks or not Notification then
        return
    end
    
    Callbacks:ServerCallback('Dealerships:StockDelivery:Start', { dealerId = dealerId, vehicle = vehicle }, function(success, message)
        if success then
            Notification:Success('Stock delivery started! Drive to the docks.', 5000, 'truck')
        else
            Notification:Error(message or 'Failed to start delivery', 5000, 'car-building')
        end
    end)
end


RegisterNetEvent('Dealerships:Client:StockDelivery:Started', function(data)
    _activeDelivery = data
    
    if not Blips then
        Blips = exports['mythic-base']:FetchComponent('Blips')
    end
    if not Callbacks then
        Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    end
    if not Notification then
        Notification = exports['mythic-base']:FetchComponent('Notification')
    end
    
    if Blips then
        _deliveryBlips.docks = Blips:Add('stock_docks', 'Docks - Pickup Location', data.docksLocation, 50, 3, 0.8, 2, false, true)
    end
    
    
    CreateThread(function()
        while _activeDelivery and _activeDelivery.state ~= 'at_docks' do
            Wait(1000)
            if Callbacks then
                Callbacks:ServerCallback('Dealerships:StockDelivery:AtDocks', {}, function(atDocks)
                    if atDocks then
                        _activeDelivery.state = 'at_docks'
                        if Notification then
                            Notification:Success('You\'ve arrived at the docks. Pick up the trailer.', 5000, 'truck')
                        end
                        TriggerEvent('Dealerships:Client:StockDelivery:AtDocks')
                    end
                end)
            end
        end
    end)
end)


RegisterNetEvent('Dealerships:Client:StockDelivery:TrailerReady', function(trailerNetId)
    _trailerEntity = NetworkGetEntityFromNetworkId(trailerNetId)
    if _trailerEntity and DoesEntityExist(_trailerEntity) then
        SetEntityAsMissionEntity(_trailerEntity, true, true)
    end
end)


RegisterNetEvent('Dealerships:Client:StockDelivery:AtDocks', function()
    if not _activeDelivery then return end

    if not Action then
        Action = exports['mythic-base']:FetchComponent('Action')
    end
    
    if not Action then
        return
    end

    CreateThread(function()
        while _activeDelivery and _activeDelivery.state == 'at_docks' do
            Wait(100)
            
            local ped = LocalPlayer.state.ped
            local veh = GetVehiclePedIsIn(ped, false)
            
            
            if veh ~= 0 and DoesEntityExist(veh) then
                _truckEntity = veh
                
                
                if _trailerEntity and DoesEntityExist(_trailerEntity) then
                    local truckCoords = GetEntityCoords(veh)
                    local trailerCoords = GetEntityCoords(_trailerEntity)
                    local distance = #(truckCoords - trailerCoords)
                    
                    
                    if GetPedInVehicleSeat(veh, -1) == ped then
                        
                        if distance <= 15.0 and not IsVehicleAttachedToTrailer(veh) then
                            _waitingForTrailerPickup = true
                            Action:Show('{keybind}primary_action{/keybind} Attach Trailer')
                        else
                            if _waitingForTrailerPickup then
                                _waitingForTrailerPickup = false
                                Action:Hide()
                            end
                        end
                    else
                        if _waitingForTrailerPickup then
                            _waitingForTrailerPickup = false
                            Action:Hide()
                        end
                    end
                end
            else
                _truckEntity = nil
                if _waitingForTrailerPickup then
                    _waitingForTrailerPickup = false
                    Action:Hide()
                end
            end
        end
        
        if _waitingForTrailerPickup then
            _waitingForTrailerPickup = false
            Action:Hide()
        end
    end)
end)


RegisterNetEvent('Dealerships:Client:StockDelivery:DrivingToDealership', function()
    if not _activeDelivery then return end

    if not Callbacks then
        Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    end
    if not Notification then
        Notification = exports['mythic-base']:FetchComponent('Notification')
    end

    CreateThread(function()
        while _activeDelivery and _activeDelivery.state == 'driving_to_dealership' do
            Wait(1000)
            if Callbacks then
                Callbacks:ServerCallback('Dealerships:StockDelivery:AtDealership', {}, function(atDealership)
                    if atDealership then
                        _activeDelivery.state = 'unloading'
                        if Notification then
                            Notification:Success('You\'ve arrived at PDM. Park the trailer to unload.', 5000, 'truck')
                        end
                        TriggerEvent('Dealerships:Client:StockDelivery:Unloading')
                    end
                end)
            end
        end
    end)
end)


RegisterNetEvent('Dealerships:Client:StockDelivery:Unloading', function()
    if not _activeDelivery then return end

    if not Action then
        Action = exports['mythic-base']:FetchComponent('Action')
    end
    
    if not Action then
        return
    end

    CreateThread(function()
        while _activeDelivery and _activeDelivery.state == 'unloading' do
            Wait(100)
            
            
            if not _activeDelivery then
                _waitingForUnload = false
                Action:Hide()
                break
            end
            
            local ped = LocalPlayer.state.ped
            local pedCoords = GetEntityCoords(ped)
            local distance = #(pedCoords - _activeDelivery.unloadLocation)

            if distance <= 5.0 then
                if not _waitingForUnload then
                    _waitingForUnload = true
                    Action:Show('{keybind}primary_action{/keybind} Unload Vehicles')
                end
            else
                if _waitingForUnload then
                    _waitingForUnload = false
                    Action:Hide()
                end
            end
        end
        
        _waitingForUnload = false
        Action:Hide()
    end)
end)


local function AttachTrailerToTruck(truck, trailer)
    if not truck or not trailer or not DoesEntityExist(truck) or not DoesEntityExist(trailer) then
        return false
    end
    
    
    local truckControl = NetworkRequestControlOfEntity(truck)
    local trailerControl = NetworkRequestControlOfEntity(trailer)
    
    local attempts = 0
    while (not NetworkHasControlOfEntity(truck) or not NetworkHasControlOfEntity(trailer)) and attempts < 50 do
        Wait(10)
        attempts = attempts + 1
    end
    
    if NetworkHasControlOfEntity(truck) and NetworkHasControlOfEntity(trailer) then
        
        AttachVehicleToTrailer(truck, trailer, 1.0)
        return true
    end
    
    return false
end


AddEventHandler('Keybinds:Client:KeyUp:primary_action', function()
    if not Callbacks then
        Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    end
    if not Notification then
        Notification = exports['mythic-base']:FetchComponent('Notification')
    end
    if not Action then
        Action = exports['mythic-base']:FetchComponent('Action')
    end
    if not Blips then
        Blips = exports['mythic-base']:FetchComponent('Blips')
    end
    
    if not Callbacks or not Notification or not Action then
        return
    end
    
    if _waitingForTrailerPickup and _activeDelivery and _activeDelivery.state == 'at_docks' and not _processingPickup then
        local ped = LocalPlayer.state.ped
        local veh = GetVehiclePedIsIn(ped, false)
        
        
        if veh ~= 0 and DoesEntityExist(veh) and GetPedInVehicleSeat(veh, -1) == ped then
            if _trailerEntity and DoesEntityExist(_trailerEntity) then
                local truckCoords = GetEntityCoords(veh)
                local trailerCoords = GetEntityCoords(_trailerEntity)
                local distance = #(truckCoords - trailerCoords)
                
                if distance <= 15.0 then
                    _processingPickup = true
                    _waitingForTrailerPickup = false
                    Action:Hide()
                    
                    
                    if AttachTrailerToTruck(veh, _trailerEntity) then
                        Wait(500) 
                        
                        
                        if IsVehicleAttachedToTrailer(veh) then
                            Callbacks:ServerCallback('Dealerships:StockDelivery:AttachTrailer', {}, function(success)
                                _processingPickup = false
                                if success then
                                    _activeDelivery.state = 'driving_to_dealership'
                                    _activeDelivery.trailerNetId = NetworkGetNetworkIdFromEntity(_trailerEntity)
                                    
                                    if not Blips then
                                        Blips = exports['mythic-base']:FetchComponent('Blips')
                                    end
                                    
                                    if Blips then
                                        Blips:Remove('stock_docks')
                                        _deliveryBlips.dealership = Blips:Add('stock_dealership', 'PDM - Delivery Location', _activeDelivery.unloadLocation, 1, 2, 0.8, 2, false, true)
                                    end
                                    
                                    Notification:Success('Trailer attached! Drive back to PDM.', 5000, 'truck')
                                    TriggerEvent('Dealerships:Client:StockDelivery:DrivingToDealership')
                                else
                                    Notification:Error('Failed to register trailer attachment', 5000, 'truck')
                                    _waitingForTrailerPickup = true
                                end
                            end)
                        else
                            _processingPickup = false
                            Notification:Error('Failed to attach trailer. Try backing up closer.', 5000, 'truck')
                            _waitingForTrailerPickup = true
                        end
                    else
                        _processingPickup = false
                        Notification:Error('Failed to attach trailer. Try backing up closer.', 5000, 'truck')
                        _waitingForTrailerPickup = true
                    end
                else
                    _processingPickup = false
                    Notification:Error('Trailer too far away. Get closer.', 3000, 'truck')
                    _waitingForTrailerPickup = true
                end
            else
                _processingPickup = false
                Notification:Error('Trailer not found', 3000, 'truck')
                _waitingForTrailerPickup = true
            end
        else
            _processingPickup = false
            Notification:Error('You must be in the driver seat of the truck', 3000, 'truck')
            _waitingForTrailerPickup = true
        end
    elseif _waitingForUnload and _activeDelivery and _activeDelivery.state == 'unloading' and not _processingUnload then
        local ped = LocalPlayer.state.ped
        local pedCoords = GetEntityCoords(ped)
        local distance = #(pedCoords - _activeDelivery.unloadLocation)
        
        if distance <= 5.0 then
            _processingUnload = true
            _waitingForUnload = false
            Action:Hide()
            
            Callbacks:ServerCallback('Dealerships:StockDelivery:Complete', {}, function(success, message)
                _processingUnload = false
                if success then
                    
                    _waitingForUnload = false
                    Action:Hide()
                    if not Blips then
                        Blips = exports['mythic-base']:FetchComponent('Blips')
                    end
                    if Blips then
                        Blips:Remove('stock_dealership')
                    end
                    _activeDelivery = nil
                    _deliveryBlips = {}
                    
                    Notification:Success(message, 7000, 'check')
                else
                    Notification:Error(message or 'Failed to complete delivery', 5000, 'truck')
                    
                    _waitingForUnload = true
                end
            end)
        end
    end
end)


AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if _activeDelivery then
            if not Callbacks then
                Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
            end
            if Callbacks then
                Callbacks:ServerCallback('Dealerships:StockDelivery:Cancel', {}, function() end)
            end
        end
        if not Blips then
            Blips = exports['mythic-base']:FetchComponent('Blips')
        end
        if Blips then
            for k, v in pairs(_deliveryBlips) do
                Blips:Remove(v)
            end
        end
        _waitingForTrailerPickup = false
        _waitingForUnload = false
        if Action then
            Action:Hide()
        end
    end
end)
