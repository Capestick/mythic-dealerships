_justBoughtFuckingBike = {}

AddEventHandler('Dealerships:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
    PedInteraction = exports['mythic-base']:FetchComponent('PedInteraction')
    Blips = exports['mythic-base']:FetchComponent('Blips')
    Notification = exports['mythic-base']:FetchComponent('Notification')
    ListMenu = exports['mythic-base']:FetchComponent('ListMenu')
    Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
end

AddEventHandler('Core:Shared:Ready', function()
    exports['mythic-base']:RequestDependencies('Dealerships', {
        'PedInteraction',
        'Blips',
        'Notification',
        'ListMenu',
        'Callbacks',
    }, function(error)
        if #error > 0 then
            return
        end
        RetrieveComponents()
    end)
end)

_bikeStands = {
    {
        coords = vector3(-1107.018, -1694.860, 3.4),
        blip = {
            sprite = 106,
            color = 17,
            scale = 0.5,
        },
        interactionPed = {
            model = `a_m_m_fatlatin_01`,
            heading = 335.0,
            scenario = 'WORLD_HUMAN_TENNIS_PLAYER',
            range = 45.0,
        },
        vehicleSpawn = vector4(-1104.368, -1695.073, 4.360, 216.545),
    },
    {
        coords = vector3(-275.791, -916.864, 30.216),
        blip = {
            sprite = 106,
            color = 17,
            scale = 0.5,
        },
        interactionPed = {
            model = `a_f_y_fitness_01`,
            heading = 72.833,
            scenario = 'WORLD_HUMAN_MUSCLE_FLEX',
            range = 60.0,
        },
        vehicleSpawn = vector4(-277.524, -914.589, 31.216, 85.471),
    },
}

_bikeStandAvailable = {
    {
        name = 'Beach Cruiser',
        model = `cruiser`,
        price = 650,
    },
    {
        name = 'BMX',
        model = `bmx`,
        price = 800,
    },
    {
        name = 'Mountain Bike',
        model = `scorcher`,
        price = 1600,
    },
    {
        name = 'Endurex Race Bike',
        model = `tribike2`,
        price = 3000,
    }
}

function CreateBikeStands()
    if not PedInteraction then
        PedInteraction = exports['mythic-base']:FetchComponent('PedInteraction')
    end
    
    if not PedInteraction then
        return
    end
    
    for k, v in ipairs(_bikeStands) do
        if v.interactionPed then
            PedInteraction:Add('bike_stand_'.. k, v.interactionPed.model, v.coords, v.interactionPed.heading, v.interactionPed.range, {
                {
                    icon = 'bicycle',
                    text = 'Bicycle Stand',
                    event = 'BikeStands:Client:Open',
                    data = { location = k },
                },
            }, 'bicycle', v.interactionPed.scenario)
        end
    end
end

function CreateBikeStandBlips()
    if not Blips then
        Blips = exports['mythic-base']:FetchComponent('Blips')
    end
    
    if not Blips then
        return
    end
    
    for k, v in ipairs(_bikeStands) do
        if v.blip then
            Blips:Add('bike_stand_'.. k, 'Bicycle Stand', v.coords, v.blip.sprite, v.blip.color, v.blip.scale)
        end
    end
end

AddEventHandler('BikeStands:Client:Open', function(entityData, data)
    if not Notification then
        Notification = exports['mythic-base']:FetchComponent('Notification')
    end
    if not ListMenu then
        ListMenu = exports['mythic-base']:FetchComponent('ListMenu')
    end
    
    if not Notification or not ListMenu then
        return
    end
    
    if _justBoughtFuckingBike[data.location] then
        return Notification:Error('You Just Bought a Bike off Me! Weirdo!')
    end

    local menuData = {
        main = {
            label = 'Bicycle Stand - Purchase a Bicycle',
            items = {}
        }
    }

    for k, v in ipairs(_bikeStandAvailable) do
        table.insert(menuData.main.items, {
            label = v.name,
            description = 'Purchase for $'.. v.price .. ' Cash',
            event = 'BikeStands:Client:Purchase',
            data = { location = data.location, bike = k },
        })
    end

    ListMenu:Show(menuData)
end)

AddEventHandler('BikeStands:Client:Purchase', function(data)
    if not Callbacks then
        Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    end
    if not Notification then
        Notification = exports['mythic-base']:FetchComponent('Notification')
    end
    
    if not Callbacks or not Notification then
        return
    end
    
    if data and data.location and data.bike then
        local bikeData = _bikeStandAvailable[data.bike]
        local locationData = _bikeStands[data.location]
        if not bikeData or not locationData then return end

        Callbacks:ServerCallback('BikeStand:Purchase', {
            name = bikeData.name,
            vehicleHash = bikeData.model,
            price = bikeData.price,
            spawnCoords = locationData.vehicleSpawn.xyz,
            spawnHeading = locationData.vehicleSpawn.w,
        }, function(success)
            if success then
                _justBoughtFuckingBike[data.location] = true
                Notification:Success(string.format('Purchased %s, It Has Been Brought out for You.', bikeData.name))
            else
                Notification:Error('Purchase Failed')
            end
        end)
    end
end)