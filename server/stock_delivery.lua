local _activeDeliveries = {}

local _config = {
    truckSpawn = {
        ['pdm'] = vector4(-16.12324, -1101.977, 26.67616, 164.45616),
    },
    trailerSpawn = {
        ['pdm'] = vector4(1203.5278, -3205.2529, 6.2048, 179.8759),
    },
    unloadLocation = {
        ['pdm'] = vector3(-16.12324, -1101.977, 26.67616),
    },
    vehiclesPerDelivery = 3,
}

function RegisterStockDeliveryCallbacks()
    
    Callbacks:RegisterServerCallback('Dealerships:StockDelivery:GetVehicles', function(source, data, cb)
        local dealerId = data and data.dealerId or nil
        
        if not dealerId or not _dealerships[dealerId] then
            cb(false)
            return
        end

        
        if not Jobs.Permissions:HasPermissionInJob(source, dealerId, 'dealership_manage') then
            cb(false)
            return
        end

        
        local vehicleDefs = {}
        local allStock = Dealerships.Stock:FetchDealer(dealerId)
        
        
        local stockMap = {}
        if allStock then
            for _, stock in ipairs(allStock) do
                stockMap[stock.vehicle] = stock
            end
        end
        
        
        local p = promise.new()
        Database.Game:find({
            collection = 'dealership_vehicles',
            query = {
                dealership = dealerId,
            }
        }, function(success, result)
            local defMap = {}
            if success then
                
                for k, v in ipairs(result) do
                    defMap[v.vehicle] = true
                    local currentStock = 0
                    if stockMap[v.vehicle] then
                        currentStock = stockMap[v.vehicle].quantity or 0
                    end
                    
                    table.insert(vehicleDefs, {
                        vehicle = v.vehicle,
                        make = v.data.make,
                        model = v.data.model,
                        price = v.data.price,
                        class = v.data.class,
                        category = v.data.category,
                        currentStock = currentStock,
                    })
                end
            end
            
            
            if allStock then
                for _, stock in ipairs(allStock) do
                    if not defMap[stock.vehicle] then
                        
                        table.insert(vehicleDefs, {
                            vehicle = stock.vehicle,
                            make = stock.data and stock.data.make or stock.vehicle,
                            model = stock.data and stock.data.model or stock.vehicle,
                            price = stock.data and stock.data.price or 0,
                            class = stock.data and stock.data.class or '?',
                            category = stock.data and stock.data.category or 'misc',
                            currentStock = stock.quantity or 0,
                        })
                    end
                end
            end
            
            p:resolve(vehicleDefs)
        end)
        
        cb(Citizen.Await(p))
    end)

    
    Callbacks:RegisterServerCallback('Dealerships:StockDelivery:Start', function(source, data, cb)
        if not data then
            cb(false, "Invalid parameters")
            return
        end
        
        local dealerId = data.dealerId
        local vehicle = data.vehicle
        local amount = 1 
        
        if not dealerId or not vehicle then
            cb(false, "Invalid parameters")
            return
        end

        
        if not Jobs.Permissions:HasPermissionInJob(source, dealerId, 'dealership_manage') then
            cb(false, "No permission")
            return
        end

        
        if _activeDeliveries[source] then
            cb(false, "You already have an active delivery")
            return
        end

        
        local vehicleDef = Dealerships.VehicleDefinitions:Fetch(dealerId, vehicle)
        if not vehicleDef then
            
            local existingStock = Dealerships.Stock:FetchDealerVehicle(dealerId, vehicle)
            if existingStock and existingStock.data then
                
                vehicleDef = {
                    modelType = existingStock.modelType or 'automobile',
                    data = existingStock.data
                }
            else
                cb(false, "Vehicle not defined. Staff must use /addvehicle first to define this vehicle.")
                return
            end
        end

        
        local truckSpawn = _config.truckSpawn[dealerId]
        if not truckSpawn then
            cb(false, "No truck spawn configured")
            return
        end

        Vehicles:SpawnTemp(source, `hauler`, vector3(truckSpawn.x, truckSpawn.y, truckSpawn.z), truckSpawn.w, function(truck, VIN, plate)
            if truck and DoesEntityExist(truck) then
                
                Vehicles.Keys:Add(source, VIN)

                
                _activeDeliveries[source] = {
                    dealerId = dealerId,
                    vehicle = vehicle,
                    amount = amount,
                    truck = truck,
                    truckVIN = VIN,
                    vehicleDef = vehicleDef,
                    state = 'driving_to_docks', 
                }

                
                local trailerSpawn = _config.trailerSpawn[dealerId]
                TriggerClientEvent('Dealerships:Client:StockDelivery:Started', source, {
                    dealerId = dealerId,
                    vehicle = vehicle,
                    amount = amount,
                    docksLocation = vector3(trailerSpawn.x, trailerSpawn.y, trailerSpawn.z),
                    unloadLocation = _config.unloadLocation[dealerId],
                })

                cb(true, "Delivery started")
            else
                cb(false, "Failed to spawn truck")
            end
        end)
    end)

    
    Callbacks:RegisterServerCallback('Dealerships:StockDelivery:AtDocks', function(source, data, cb)
        local delivery = _activeDeliveries[source]
        if not delivery then
            cb(false)
            return
        end

        if delivery.state == 'driving_to_docks' then
            local playerPed = GetPlayerPed(source)
            local playerCoords = GetEntityCoords(playerPed)
            local trailerSpawn = _config.trailerSpawn[delivery.dealerId]
            
            if not trailerSpawn then
                cb(false)
                return
            end
            
            local distance = #(playerCoords - vector3(trailerSpawn.x, trailerSpawn.y, trailerSpawn.z))

            if distance <= 10.0 then
                delivery.state = 'at_docks'
                
                
                if not delivery.trailer then
                    local trailerModel = `tr4`
                    Vehicles:SpawnTemp(-1, trailerModel, vector3(trailerSpawn.x, trailerSpawn.y, trailerSpawn.z), trailerSpawn.w, function(trailer, trailerVIN)
                        if trailer and DoesEntityExist(trailer) then
                            delivery.trailer = trailer
                            delivery.trailerVIN = trailerVIN
                            
                            
                            TriggerClientEvent('Dealerships:Client:StockDelivery:TrailerReady', source, NetworkGetNetworkIdFromEntity(trailer))
                        end
                    end)
                end
                
                cb(true)
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)

    
    Callbacks:RegisterServerCallback('Dealerships:StockDelivery:AttachTrailer', function(source, data, cb)
        local delivery = _activeDeliveries[source]
        if not delivery or delivery.state ~= 'at_docks' or not delivery.trailer then
            cb(false)
            return
        end

        delivery.state = 'driving_to_dealership'
        cb(true)
    end)

    
    Callbacks:RegisterServerCallback('Dealerships:StockDelivery:AtDealership', function(source, data, cb)
        local delivery = _activeDeliveries[source]
        if not delivery then
            cb(false)
            return
        end

        if delivery.state == 'driving_to_dealership' then
            local unloadLoc = _config.unloadLocation[delivery.dealerId]
            if not unloadLoc then
                cb(false)
                return
            end

            local playerPed = GetPlayerPed(source)
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - unloadLoc)

            if distance <= 15.0 then
                delivery.state = 'unloading'
                cb(true)
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)

    
    Callbacks:RegisterServerCallback('Dealerships:StockDelivery:Complete', function(source, data, cb)
        local delivery = _activeDeliveries[source]
        if not delivery or delivery.state ~= 'unloading' then
            cb(false, "Invalid state")
            return
        end

        
        local res = Dealerships.Stock:Add(delivery.dealerId, delivery.vehicle, delivery.vehicleDef.modelType, delivery.amount, delivery.vehicleDef.data)

        if res and res.success then
            
            if delivery.trailer and DoesEntityExist(delivery.trailer) then
                Vehicles:Delete(delivery.trailer, function() end)
            end

            
            if delivery.truck and DoesEntityExist(delivery.truck) then
                Vehicles:Delete(delivery.truck, function() end)
            end

            
            _activeDeliveries[source] = nil
            cb(true, string.format("Delivery complete! Added %d %s to stock", delivery.amount, delivery.vehicleDef.data.model))
        else
            cb(false, "Failed to add stock")
        end
    end)

    
    Callbacks:RegisterServerCallback('Dealerships:StockDelivery:Cancel', function(source, data, cb)
        local delivery = _activeDeliveries[source]
        if not delivery then
            cb(false)
            return
        end

        
        if delivery.truck and DoesEntityExist(delivery.truck) then
            Vehicles:Delete(delivery.truck, function() end)
        end
        if delivery.trailer and DoesEntityExist(delivery.trailer) then
            Vehicles:Delete(delivery.trailer, function() end)
        end

        _activeDeliveries[source] = nil
        cb(true)
    end)
end

AddEventHandler('Dealerships:Server:RegisterCallbacks', function()
    RegisterStockDeliveryCallbacks()
end)
