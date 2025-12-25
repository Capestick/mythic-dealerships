SHOWROOM_CACHE = {}

AddEventHandler('Dealerships:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
    Game = exports['mythic-base']:FetchComponent('Game')
    Vehicles = exports['mythic-base']:FetchComponent('Vehicles')
end

AddEventHandler('Core:Shared:Ready', function()
    exports['mythic-base']:RequestDependencies('Dealerships', {
        'Game',
        'Vehicles',
    }, function(error)
        if #error > 0 then
            return
        end
        RetrieveComponents()
    end)
end)

function SpawnShowroom(id)
    if not Game then
        Game = exports['mythic-base']:FetchComponent('Game')
    end
    
    if not Vehicles then
        Vehicles = exports['mythic-base']:FetchComponent('Vehicles')
    end
    
    if not Game or not Vehicles then
        return
    end
    
    if SHOWROOM_CACHE[id] then
        DeleteShowroom(id)
    end

    if _dealerships[id] and GlobalState.DealershipShowrooms[id] then
        local spawnVehicles = {}
        for slot, data in pairs(GlobalState.DealershipShowrooms[id]) do
            local spawnPoint = _dealerships[id].showroom[tonumber(slot)]
            Game.Vehicles:SpawnLocal(spawnPoint.xyz, data.vehicle, spawnPoint.w, function(veh)
                if not SHOWROOM_CACHE[id] then
                    SHOWROOM_CACHE[id] = {}
                end

                SHOWROOM_CACHE[id][slot] = veh

                Vehicles.Properties:Set(veh, data.properties)

                FreezeEntityPosition(veh, true)
                SetVehicleDoorsLocked(veh, 2)
                SetVehicleLights(veh, 2)
                SetVehicleHasUnbreakableLights(veh, true)
                SetVehicleNumberPlateText(veh, '')
                SetVehicleDirtLevel(veh, 0.0)
                RollDownWindows(veh)
            end)
            Wait(100)
        end
    end
end

function DeleteShowroom(id)
    if not Game then
        Game = exports['mythic-base']:FetchComponent('Game')
    end
    
    if not Game then
        return
    end
    
    if SHOWROOM_CACHE[id] then
        for k, v in pairs(SHOWROOM_CACHE[id]) do
            Game.Vehicles:Delete(v)
        end
        SHOWROOM_CACHE[id] = nil
    end
end

RegisterNetEvent('Dealerships:Client:ShowroomUpdate', function(dealerId)
    if _withinShowroom and _withinShowroom == dealerId then
        Wait(500)
        DeleteShowroom(_withinShowroom)
        Wait(150)
        SpawnShowroom(_withinShowroom)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and _withinShowroom then
        DeleteShowroom(_withinShowroom)
    end
end)