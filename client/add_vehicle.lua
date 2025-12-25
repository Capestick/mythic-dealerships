-- Use the same dependency system as client.lua
local Callbacks, Notification, Input

AddEventHandler('Dealerships:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
    Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    Notification = exports['mythic-base']:FetchComponent('Notification')
    Input = exports['mythic-base']:FetchComponent('Input')
end

AddEventHandler('Core:Shared:Ready', function()
    exports['mythic-base']:RequestDependencies('Dealerships', {
        'Callbacks',
        'Notification',
        'Input',
    }, function(error)
        if #error > 0 then
            return
        end
        RetrieveComponents()
    end)
end)

RegisterNetEvent("Dealerships:Client:AddVehicle")
AddEventHandler("Dealerships:Client:AddVehicle", function()
    if not Input then
        Input = exports['mythic-base']:FetchComponent('Input')
    end
    if not Input then
        print("[DEALERSHIPS] Input component not available")
        return
    end
    
    Input:Show(
        "Add Vehicle to Dealership",
        "Enter Vehicle Information",
        {
            {
                id = "dealership",
                type = "text",
                options = {
                    label = "Dealership ID",
                    inputProps = {
                        placeholder = "e.g. pdm, tuna, redline",
                        maxLength = 50,
                    },
                },
            },
            {
                id = "vehicle",
                type = "text",
                options = {
                    label = "Vehicle ID",
                    inputProps = {
                        placeholder = "e.g. cuzzy, oceanic",
                        maxLength = 50,
                    },
                },
            },
            {
                id = "modelType",
                type = "text",
                options = {
                    label = "Model Type",
                    inputProps = {
                        placeholder = "automobile, bike, boat, heli, plane, submarine, trailer",
                        maxLength = 20,
                    },
                },
            },
            {
                id = "price",
                type = "number",
                options = {
                    label = "Price",
                    inputProps = {
                        placeholder = "Price (Before commission)",
                        min = 0,
                        max = 99999999,
                    },
                },
            },
            {
                id = "class",
                type = "text",
                options = {
                    label = "Class",
                    inputProps = {
                        placeholder = "e.g. B, C, D",
                        maxLength = 10,
                    },
                },
            },
            {
                id = "make",
                type = "text",
                options = {
                    label = "Make",
                    inputProps = {
                        placeholder = "e.g. Bravado, Declasse",
                        maxLength = 50,
                    },
                },
            },
            {
                id = "model",
                type = "text",
                options = {
                    label = "Model",
                    inputProps = {
                        placeholder = "e.g. Oceanic, Dominator",
                        maxLength = 50,
                    },
                },
            },
            {
                id = "category",
                type = "text",
                options = {
                    label = "Category",
                    inputProps = {
                        placeholder = "e.g. sedan, suv, compact",
                        maxLength = 50,
                    },
                },
            },
        },
        "Dealerships:Client:AddVehicleInput",
        {}
    )
end)

AddEventHandler("Dealerships:Client:AddVehicleInput", function(values, data)
    if not values or not values.dealership or not values.vehicle or not values.modelType or not values.price or not values.class or not values.make or not values.model or not values.category then
        return
    end

    if not Callbacks then
        Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    end
    if not Callbacks then
        print("[DEALERSHIPS] Callbacks component not available")
        return
    end
    
    Callbacks:ServerCallback("Dealerships:AddVehicle", {
        dealership = values.dealership,
        vehicle = values.vehicle,
        modelType = values.modelType,
        price = tonumber(values.price),
        class = values.class,
        make = values.make,
        model = values.model,
        category = values.category,
    }, function(success, message)
        if not Notification then
            Notification = exports['mythic-base']:FetchComponent('Notification')
        end
        
        if Notification then
            if success then
                Notification:Success(message or "Vehicle definition added successfully", 5000)
            else
                Notification:Error(message or "Failed to add vehicle definition", 5000)
            end
        else
            -- Fallback if Notification isn't available
            print(string.format("[DEALERSHIPS] %s: %s", success and "Success" or "Error", message or (success and "Vehicle definition added successfully" or "Failed to add vehicle definition")))
        end
    end)
end)

