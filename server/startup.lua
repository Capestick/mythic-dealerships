local _ran = false
local Tasks, Database, Logger, Dealerships

-- Automatic Stocking Configuration
local _autoStockConfig = {
    minStockLevel = 5,  -- Restock when quantity falls below this
    targetStockLevel = 10,  -- Restock to this amount
    checkInterval = 60,  -- Check every 60 minutes
}

function AutoStockDealerships()
    if not Tasks then
        Tasks = exports['mythic-base']:FetchComponent('Tasks')
    end
    if not Database then
        Database = exports['mythic-base']:FetchComponent('Database')
    end
    if not Logger then
        Logger = exports['mythic-base']:FetchComponent('Logger')
    end
    if not Dealerships then
        Dealerships = exports['mythic-base']:FetchComponent('Dealerships')
    end
    
    if not Tasks or not Database or not Logger or not Dealerships then
        return
    end

    CreateThread(function()
        for dealerId, dealerData in pairs(_dealerships) do
            -- Get all vehicle definitions for this dealership
            local p = promise.new()
            Database.Game:find({
                collection = 'dealership_vehicles',
                query = {
                    dealership = dealerId,
                }
            }, function(success, vehicleDefs)
                if success and vehicleDefs then
                    p:resolve(vehicleDefs)
                else
                    p:resolve({})
                end
            end)
            
            local vehicleDefs = Citizen.Await(p)
            
            -- Check each vehicle definition
            for _, vehDef in ipairs(vehicleDefs) do
                local currentStock = Dealerships.Stock:FetchDealerVehicle(dealerId, vehDef.vehicle)
                local currentQuantity = 0
                
                if currentStock then
                    currentQuantity = currentStock.quantity or 0
                end
                
                -- If stock is below minimum, restock to target level
                if currentQuantity < _autoStockConfig.minStockLevel then
                    local needed = _autoStockConfig.targetStockLevel - currentQuantity
                    if needed > 0 then
                        local result = Dealerships.Stock:Add(
                            dealerId,
                            vehDef.vehicle,
                            vehDef.modelType or 'automobile',
                            needed,
                            vehDef.data
                        )
                        
                        if result and result.success then
                            Logger:Info('Dealerships', string.format(
                                'Auto-stocked %d %s at %s (was %d, now %d)',
                                needed,
                                vehDef.vehicle,
                                dealerId,
                                currentQuantity,
                                _autoStockConfig.targetStockLevel
                            ))
                        end
                    end
                end
            end
        end
    end)
end

function LoadDealershipShit()
    if not _ran then
        _ran = true

        -- Ensure all components are fetched
        if not Dealerships then
            Dealerships = exports['mythic-base']:FetchComponent('Dealerships')
        end
        if not Database then
            Database = exports['mythic-base']:FetchComponent('Database')
        end
        if not Logger then
            Logger = exports['mythic-base']:FetchComponent('Logger')
        end
        if not Default then
            Default = exports['mythic-base']:FetchComponent('Default')
        end

        GlobalState.DealershipShowrooms = {}
        Dealerships.Showroom:Load()
        Dealerships.Management:LoadData()

        -- Dealerships.Stock:Ensure('pdm', 'blista', 20, {
        --     make = 'Dinka',
        --     model = 'Blista',
        --     class = 'B',
        --     category = 'compact',
        --     price = 12500,
        -- })

        -- Dealerships.Stock:Ensure('pdm', 'asbo', 20, {
        --     make = 'Maxwell',
        --     model = 'Asbo',
        --     class = 'C',
        --     category = 'compact',
        --     price = 9000,
        -- })


        local vehicleStockData = {
                {
                    vehicle = "asbo",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 4000,
                        make = "Maxwell",
                        model = "Asbo",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "blista",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 13000,
                        make = "Dinka",
                        model = "Blista",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "brioso",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 20000,
                        make = "Grotti",
                        model = "Brioso R/A",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "club",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 8000,
                        make = "BF",
                        model = "Club",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dilettante",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 9000,
                        make = "Karin",
                        model = "Dilettante",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dilettante2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 12000,
                        make = "Karin",
                        model = "Dilettante Patrol",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "kanjo",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 12000,
                        make = "Dinka",
                        model = "Blista Kanjo",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "issi2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 7000,
                        make = "Weeny",
                        model = "Issi",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "issi3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 5000,
                        make = "Weeny",
                        model = "Issi Classic",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "issi4",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 80000,
                        make = "Weeny",
                        model = "Issi Arena",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "issi5",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 80000,
                        make = "Weeny",
                        model = "Issi Future Shock",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "issi6",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 80000,
                        make = "Weeny",
                        model = "Issi Nightmare",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "panto",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 3200,
                        make = "Benefactor",
                        model = "Panto",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "prairie",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 30000,
                        make = "Bollokan",
                        model = "Prairie",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "rhapsody",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 10000,
                        make = "Declasse",
                        model = "Rhapsody",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "brioso2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 12000,
                        make = "Grotti",
                        model = "Brioso 300",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "weevil",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 9000,
                        make = "BF",
                        model = "Weevil",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "issi7",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 100000,
                        make = "Weeny",
                        model = "Issi Sport",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "blista2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 18950,
                        make = "Dinka",
                        model = "Blista Compact",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "blista3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 15000,
                        make = "Dinka",
                        model = "Blista Go Go Monkey",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "brioso3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 125000,
                        make = "Grotti",
                        model = "Brioso 300 Widebody",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "boor",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 23000,
                        make = "Karin",
                        model = "Boor",
                        category = "compact"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "asea",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 2500,
                        make = "Declasse",
                        model = "Asea",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "asterope",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 11000,
                        make = "Karin",
                        model = "Asterope",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "cog55",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 22000,
                        make = "Enus",
                        model = "Cognoscenti 55",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "cognoscenti",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 22500,
                        make = "Enus",
                        model = "Cognoscenti",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "emperor",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 4250,
                        make = "Albany",
                        model = "Emperor",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "fugitive",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 20000,
                        make = "Cheval",
                        model = "Fugitive",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "glendale",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 3400,
                        make = "Benefactor",
                        model = "Glendale",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "glendale2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 12000,
                        make = "Benefactor",
                        model = "Glendale Custom",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "ingot",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 4999,
                        make = "Vulcar",
                        model = "Ingot",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "intruder",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 11250,
                        make = "Karin",
                        model = "Intruder",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "premier",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 12000,
                        make = "Declasse",
                        model = "Premier",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "primo",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 5000,
                        make = "Albany",
                        model = "Primo",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "primo2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 14500,
                        make = "Albany",
                        model = "Primo Custom",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "regina",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 7000,
                        make = "Dundreary",
                        model = "Regina",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "stafford",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 30000,
                        make = "Enus",
                        model = "Stafford",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "stanier",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 19000,
                        make = "Vapid",
                        model = "Stanier",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "stratum",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 15000,
                        make = "Zirconium",
                        model = "Stratum",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "stretch",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 19000,
                        make = "Dundreary",
                        model = "Stretch",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "superd",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 17000,
                        make = "Enus",
                        model = "Super Diamond",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "surge",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 20000,
                        make = "Cheval",
                        model = "Surge",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "tailgater",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 22000,
                        make = "Obey",
                        model = "Tailgater",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "warrener",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 4000,
                        make = "Vulcar",
                        model = "Warrener",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "washington",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 7000,
                        make = "Albany",
                        model = "Washington",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "tailgater2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 51000,
                        make = "Obey",
                        model = "Tailgater S",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "cinquemila",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 125000,
                        make = "Cinquemila",
                        model = "Lampadati",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "iwagen",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 225000,
                        make = "I-Wagen",
                        model = "Obey",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "astron",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 150000,
                        make = "Pfister",
                        model = "Astron",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "baller7",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 145000,
                        make = "Gallivanter",
                        model = "Baller ST",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "comet7",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 25000,
                        make = "S2 Cabrio",
                        model = "Comet",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "deity",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 505000,
                        make = "Enus",
                        model = "Deity",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "jubilee",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 485000,
                        make = "Enus",
                        model = "Jubilee",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "oracle",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 22000,
                        make = "Übermacht",
                        model = "Oracle",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "schafter2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 16000,
                        make = "Benefactor",
                        model = "Schafter",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "warrener2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 30000,
                        make = "Vulcar",
                        model = "Warrener HKR",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "rhinehart",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 105000,
                        make = "Übermacht",
                        model = "Rhinehart",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "eudora",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 17000,
                        make = "Willard",
                        model = "Eudora",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "asterope2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 459000,
                        make = "Karin",
                        model = "Asterope GZ",
                        category = "sedans"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "baller",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 22000,
                        make = "Gallivanter",
                        model = "Baller",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "baller2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 15000,
                        make = "Gallivanter",
                        model = "Baller II",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "baller3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 15000,
                        make = "Gallivanter",
                        model = "Baller LE",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "baller4",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 29000,
                        make = "Gallivanter",
                        model = "Baller LE LWB",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "baller5",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 78000,
                        make = "Gallivanter",
                        model = "Baller LE (Armored)",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "baller6",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 82000,
                        make = "Gallivanter",
                        model = "Baller LE LWB (Armored)",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "bjxl",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 19000,
                        make = "Karin",
                        model = "BeeJay XL",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "cavalcade",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 14000,
                        make = "Albany",
                        model = "Cavalcade",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "cavalcade2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 16500,
                        make = "Albany",
                        model = "Cavalcade II",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "contender",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 35000,
                        make = "Vapid",
                        model = "Contender",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dubsta",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 19000,
                        make = "Benefactor",
                        model = "Dubsta",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dubsta2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 19500,
                        make = "Benefactor",
                        model = "Dubsta Luxury",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "fq2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 18500,
                        make = "Fathom",
                        model = "FQ2",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "granger",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 22000,
                        make = "Declasse",
                        model = "Granger",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "gresley",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 25000,
                        make = "Bravado",
                        model = "Gresley",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "habanero",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 20000,
                        make = "Emperor",
                        model = "Habanero",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "huntley",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 24500,
                        make = "Enus",
                        model = "Huntley S",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "landstalker",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 12000,
                        make = "Dundreary",
                        model = "Landstalker",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "landstalker2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 26000,
                        make = "Dundreary",
                        model = "Landstalker XL",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "novak",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 70000,
                        make = "Lampadati",
                        model = "Novak",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "patriot",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 21000,
                        make = "Mammoth",
                        model = "Patriot",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "patriot2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 21000,
                        make = "Mammoth",
                        model = "Patriot Stretch",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "radi",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 18000,
                        make = "Vapid",
                        model = "Radius",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "rebla",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 21000,
                        make = "Übermacht",
                        model = "Rebla GTS",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "rocoto",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 13000,
                        make = "Obey",
                        model = "Rocoto",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "seminole",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 20000,
                        make = "Canis",
                        model = "Seminole",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "seminole2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 13000,
                        make = "Canis",
                        model = "Seminole Frontier",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "serrano",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 48000,
                        make = "Benefactor",
                        model = "Serrano",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "toros",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 65000,
                        make = "Pegassi",
                        model = "Toros",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "xls",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 17000,
                        make = "Benefactor",
                        model = "XLS",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "granger2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 221000,
                        make = "Declasse",
                        model = "Granger 3600LX",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "patriot3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 270000,
                        make = "Mil-Spec",
                        model = "Patriot Military",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "aleutian",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 183500,
                        make = "Vapid",
                        model = "Aleutian",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "baller8",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 171500,
                        make = "Gallivanter",
                        model = "Baller ST-D",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "cavalcade3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 166500,
                        make = "Albany",
                        model = "Cavalcade XL",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dorado",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 137500,
                        make = "Bravado",
                        model = "Dorado",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "vivanite",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 160500,
                        make = "Karin",
                        model = "Vivanite",
                        category = "suv"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "cogcabrio",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 30000,
                        make = "Enus",
                        model = "Cognoscenti Cabrio",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "exemplar",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 40000,
                        make = "Dewbauchee",
                        model = "Exemplar",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "f620",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 32500,
                        make = "Ocelot",
                        model = "F620",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "felon",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 31000,
                        make = "Lampadati",
                        model = "Felon",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "felon2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 37000,
                        make = "Lampadati",
                        model = "Felon GT",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "jackal",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 19000,
                        make = "Ocelot",
                        model = "Jackal",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "oracle2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 28000,
                        make = "Übermacht",
                        model = "Oracle XS",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "sentinel",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 30000,
                        make = "Übermacht",
                        model = "Sentinel",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "sentinel2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 33000,
                        make = "Übermacht",
                        model = "Sentinel XS",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "windsor",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 27000,
                        make = "Enus",
                        model = "Windsor",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "windsor2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 34000,
                        make = "Enus",
                        model = "Windsor Drop",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "zion",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 22000,
                        make = "Übermacht",
                        model = "Zion",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "zion2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 28000,
                        make = "Übermacht",
                        model = "Zion Cabrio",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "previon",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 149000,
                        make = "Karin",
                        model = "Previon",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "champion",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 205000,
                        make = "Dewbauchee",
                        model = "Champion",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "futo",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 17500,
                        make = "Karin",
                        model = "Futo",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "sentinel3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 70000,
                        make = "Übermacht",
                        model = "Sentinel Classic",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "kanjosj",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 143000,
                        make = "Dinka",
                        model = "Kanjo SJ",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "postlude",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 90000,
                        make = "Dinka",
                        model = "Postlude",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "tahoma",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 12000,
                        make = "Declasse",
                        model = "Tahoma Coupe",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "broadway",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 20000,
                        make = "Classique",
                        model = "Broadway",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "fr36",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 161000,
                        make = "Fathom",
                        model = "FR36",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "blade",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 23500,
                        make = "Vapid",
                        model = "Blade",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "buccaneer",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 22500,
                        make = "Albany",
                        model = "Buccaneer",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "buccaneer2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 24500,
                        make = "Albany",
                        model = "Buccaneer Rider",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "chino",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 5000,
                        make = "Vapid",
                        model = "Chino",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "chino2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 8000,
                        make = "Vapid",
                        model = "Chino Luxe",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "clique",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 20000,
                        make = "Vapid",
                        model = "Clique",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "coquette3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 180000,
                        make = "Invetero",
                        model = "Coquette BlackFin",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "deviant",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 70000,
                        make = "Schyster",
                        model = "Deviant",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dominator",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 62500,
                        make = "Vapid",
                        model = "Dominator",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dominator2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 50000,
                        make = "Vapid",
                        model = "Pißwasser Dominator",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dominator3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 70000,
                        make = "Vapid",
                        model = "Dominator GTX",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dominator4",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 200000,
                        make = "Vapid",
                        model = "Dominator Arena",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dominator7",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 110000,
                        make = "Vapid",
                        model = "Dominator ASP",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dominator8",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 80000,
                        make = "Vapid",
                        model = "Dominator GTT",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dukes",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 23500,
                        make = "Imponte",
                        model = "Dukes",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dukes2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 60000,
                        make = "Imponte",
                        model = "Duke O'Death",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dukes3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 45000,
                        make = "Imponte",
                        model = "Beater Dukes",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "faction",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 17000,
                        make = "Willard",
                        model = "Faction",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "faction2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 19000,
                        make = "Willard",
                        model = "Faction Rider",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "faction3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 35000,
                        make = "Willard",
                        model = "Faction Custom Donk",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "ellie",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 42250,
                        make = "Vapid",
                        model = "Ellie",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "gauntlet",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 28500,
                        make = "Bravado",
                        model = "Gauntlet",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "gauntlet2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 70000,
                        make = "Bravado",
                        model = "Redwood Gauntlet",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "gauntlet3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 75000,
                        make = "Bravado",
                        model = "Classic Gauntlet",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "gauntlet4",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 80000,
                        make = "Bravado",
                        model = "Gauntlet Hellfire",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "gauntlet5",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 120000,
                        make = "Bravado",
                        model = "Gauntlet Classic Custom",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "hermes",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 535000,
                        make = "Albany",
                        model = "Hermes",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "hotknife",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 90000,
                        make = "Vapid",
                        model = "Hotknife",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "hustler",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 95000,
                        make = "Vapid",
                        model = "Hustler",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "impaler",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 95000,
                        make = "Vapid",
                        model = "Impaler",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "impaler2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 95000,
                        make = "Vapid",
                        model = "Impaler Arena",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "impaler3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 95000,
                        make = "Vapid",
                        model = "Impaler Future Shock",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "impaler4",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 95000,
                        make = "Vapid",
                        model = "Impaler Nightmare",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "imperator",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 95000,
                        make = "Vapid",
                        model = "Imperator Arena",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "imperator2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 95000,
                        make = "Vapid",
                        model = "imperator Future Shock",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "imperator3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 95000,
                        make = "Vapid",
                        model = "Imperator Nightmare",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "lurcher",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 21000,
                        make = "Bravado",
                        model = "Lurcher",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "nightshade",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 70000,
                        make = "Imponte",
                        model = "Nightshade",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "phoenix",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 65000,
                        make = "Imponte",
                        model = "Phoenix",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "picador",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 20000,
                        make = "Cheval",
                        model = "Picador",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "ratloader2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 20000,
                        make = "Ratloader2",
                        model = "Ratloader",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "ruiner",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 29000,
                        make = "Imponte",
                        model = "Ruiner",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "ruiner2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 50000,
                        make = "Imponte",
                        model = "Ruiner 2000",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "sabregt",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 23000,
                        make = "Declasse",
                        model = "Sabre GT Turbo",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "sabregt2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 26500,
                        make = "Declasse",
                        model = "Sabre GT Turbo Custom",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "slamvan",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 30000,
                        make = "Vapid",
                        model = "Slam Van",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "slamvan2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 90000,
                        make = "Vapid",
                        model = "Lost Slam Van",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "slamvan3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 17000,
                        make = "Vapid",
                        model = "Slam Van Custom",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "stalion",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 33000,
                        make = "Declasse",
                        model = "Stallion",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "stalion2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 40000,
                        make = "Declasse",
                        model = "Stallion Burgershot",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "tampa",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 24500,
                        make = "Declasse",
                        model = "Tampa",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "tulip",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 80000,
                        make = "Declasse",
                        model = "Tulip",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "vamos",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 30000,
                        make = "Declasse",
                        model = "Vamos",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "vigero",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 39500,
                        make = "Declasse",
                        model = "Vigero",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "virgo",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 22000,
                        make = "Albany",
                        model = "Virgo",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "virgo2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 21000,
                        make = "Dundreary",
                        model = "Virgo Custom Classic",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "virgo3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 21000,
                        make = "Dundreary",
                        model = "Virgo Classic",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "voodoo",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 13000,
                        make = "Declasse",
                        model = "Voodoo",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "yosemite",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 19500,
                        make = "Declasse",
                        model = "Yosemite",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "yosemite2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 55000,
                        make = "Declasse",
                        model = "Yosemite Drift",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "buffalo4",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 345000,
                        make = "Bravado",
                        model = "Buffalo STX",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "manana",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 12800,
                        make = "Albany",
                        model = "Manana",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "manana2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 24000,
                        make = "Albany",
                        model = "Manana Custom",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "tampa2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 80000,
                        make = "Declasse",
                        model = "Drift Tampa",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "ruiner4",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 85000,
                        make = "Imponte",
                        model = "Ruiner ZZ-8",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "vigero2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 105000,
                        make = "Declasse",
                        model = "Vigero ZX",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "weevil2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 95000,
                        make = "BF",
                        model = "Weevil Custom",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "buffalo5",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 214000,
                        make = "Bravado",
                        model = "Buffalo EVX",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "tulip2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 80000,
                        make = "Declasse",
                        model = "Tulip M-100",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "clique2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 102500,
                        make = "Vapid",
                        model = "Clique Wagon",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "brigham",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 149900,
                        make = "Albany",
                        model = "Brigham",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "greenwood",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 105000,
                        make = "Bravado",
                        model = "Greenwood",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dominator9",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 219500,
                        make = "Vapid",
                        model = "Dominator GT",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "impaler6",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 146500,
                        make = "Declasse",
                        model = "Impaler LX",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "vigero3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 229500,
                        make = "Declasse",
                        model = "Vigero ZX Convertible",
                        category = "muscle"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "ardent",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 30000,
                        make = "Ocelot",
                        model = "Ardent",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "btype",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 75000,
                        make = "Albany",
                        model = "Roosevelt",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "btype2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 87000,
                        make = "Albany",
                        model = "Franken Stange",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "btype3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 63000,
                        make = "Albany",
                        model = "Roosevelt Valor",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "casco",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 100000,
                        make = "Lampadati",
                        model = "Casco",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "deluxo",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 55000,
                        make = "Imponte",
                        model = "Deluxo",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dynasty",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 25000,
                        make = "Weeny",
                        model = "Dynasty",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "fagaloa",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 13000,
                        make = "Vulcar",
                        model = "Fagaloa",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "feltzer3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 115000,
                        make = "Benefactor",
                        model = "Stirling GT",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "gt500",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 130000,
                        make = "Grotti",
                        model = "GT500",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "infernus2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 245000,
                        make = "Pegassi",
                        model = "Infernus Classic",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "jb700",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 240000,
                        make = "Dewbauchee",
                        model = "JB 700",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "jb7002",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 40000,
                        make = "Dewbauchee",
                        model = "JB 700W",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "mamba",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 140000,
                        make = "Declasse",
                        model = "Mamba",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "michelli",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 30000,
                        make = "Lampadati",
                        model = "Michelli GT",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "monroe",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 115000,
                        make = "Pegassi",
                        model = "Monroe",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "nebula",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 22000,
                        make = "Vulcar",
                        model = "Nebula",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "peyote",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 23500,
                        make = "Vapid",
                        model = "Peyote",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "peyote3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 48000,
                        make = "Vapid",
                        model = "Peyote Custom",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "pigalle",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 92000,
                        make = "Lampadati",
                        model = "Pigalle",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "rapidgt3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 90000,
                        make = "Dewbauchee",
                        model = "Rapid GT Classic",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "retinue",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 32000,
                        make = "Vapid",
                        model = "Retinue",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "retinue2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 38000,
                        make = "Vapid",
                        model = "Retinue MKII",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "savestra",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 67000,
                        make = "Annis",
                        model = "Savestra",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "stinger",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 39500,
                        make = "Grotti",
                        model = "Stinger",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "stingergt",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 70000,
                        make = "Grotti",
                        model = "Stinger GT",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "stromberg",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 80000,
                        make = "Ocelot",
                        model = "Stromberg",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "swinger",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 221000,
                        make = "Ocelot",
                        model = "Swinger",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "torero",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 84000,
                        make = "Pegassi",
                        model = "Torero",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "tornado",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 21000,
                        make = "Declasse",
                        model = "Tornado",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "tornado2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 22000,
                        make = "Declasse",
                        model = "Tornado Convertible",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "tornado5",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 22000,
                        make = "Declasse",
                        model = "Tornado Custom",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "turismo2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 170000,
                        make = "Grotti",
                        model = "Turismo Classic",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "viseris",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 210000,
                        make = "Lampadati",
                        model = "Viseris",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "z190",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 78000,
                        make = "Karin",
                        model = "190Z",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "ztype",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 270000,
                        make = "Truffade",
                        model = "Z-Type",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "zion3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 45000,
                        make = "Übermacht",
                        model = "Zion Classic",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "cheburek",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 7000,
                        make = "Rune",
                        model = "Cheburek",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "toreador",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 50000,
                        make = "Pegassi",
                        model = "Toreador",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "peyote2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 40000,
                        make = "Vapid",
                        model = "Peyote Gasser",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "coquette2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "A",
                        price = 165000,
                        make = "Invetero",
                        model = "Coquette Classic",
                        category = "sportclassic"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "stingertt",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 238000,
                        make = "Maibatsu",
                        model = "Itali GTO Stinger TT",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "everon2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 80000,
                        make = "Karin",
                        model = "Everon Hotring",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "issi8",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 10000,
                        make = "Weeny",
                        model = "Issi Rally",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "gauntlet6",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 181000,
                        make = "Bravado",
                        model = "Hotring Hellfire",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "coureur",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 199000,
                        make = "Penaud",
                        model = "La Coureuse",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "r300",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 56000,
                        make = "Annis",
                        model = "300R",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "panthere",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S",
                        price = 55000,
                        make = "Toundra",
                        model = "Panthere",
                        category = "sport"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "ignus",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S+",
                        price = 1120000,
                        make = "Pegassi",
                        model = "Ignus",
                        category = "super"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "zeno",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "S+",
                        price = 1350000,
                        make = "Överflöd",
                        model = "Zeno",
                        category = "super"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "akuma",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 55000,
                        make = "Dinka",
                        model = "Akuma",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "avarus",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 20000,
                        make = "LCC",
                        model = "Avarus",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "bagger",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 13500,
                        make = "WMC",
                        model = "Bagger",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "bati",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 24000,
                        make = "Pegassi",
                        model = "Bati 801",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "bati2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 19000,
                        make = "Pegassi",
                        model = "Bati 801RR",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "bf400",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 22000,
                        make = "Nagasaki",
                        model = "BF400",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "carbonrs",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 22000,
                        make = "Nagasaki",
                        model = "Carbon RS",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "chimera",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 21000,
                        make = "Nagasaki",
                        model = "Chimera",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "cliffhanger",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 28500,
                        make = "Western",
                        model = "Cliffhanger",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "daemon",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 14000,
                        make = "WMC",
                        model = "Daemon",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "daemon2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 23000,
                        make = "Western",
                        model = "Daemon Custom",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "defiler",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 30000,
                        make = "Shitzu",
                        model = "Defiler",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "deathbike",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 30000,
                        make = "Deathbike",
                        model = "Deathbike Apocalypse",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "deathbike2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 30000,
                        make = "Deathbike",
                        model = "Deathbike Future Shock",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "deathbike3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 30000,
                        make = "Deathbike",
                        model = "Deathbike Nightmare",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "diablous",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 30000,
                        make = "Principe",
                        model = "Diablous",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "diablous2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 38000,
                        make = "Principe",
                        model = "Diablous Custom",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "double",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 28000,
                        make = "Dinka",
                        model = "Double-T",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "enduro",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 5500,
                        make = "Dinka",
                        model = "Enduro",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "esskey",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 12000,
                        make = "Pegassi",
                        model = "Esskey",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "faggio",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 2000,
                        make = "Pegassi",
                        model = "Faggio Sport",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "faggio2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 1900,
                        make = "Pegassi",
                        model = "Faggio",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "faggio3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 2500,
                        make = "Pegassi",
                        model = "Faggio Mod",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "fcr",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 5000,
                        make = "Pegassi",
                        model = "FCR 1000",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "fcr2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 19000,
                        make = "Pegassi",
                        model = "FCR 1000 Custom",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "gargoyle",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 32000,
                        make = "Western",
                        model = "Gargoyle",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "hakuchou",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 17000,
                        make = "Shitzu",
                        model = "Hakuchou",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "hakuchou2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 45000,
                        make = "Shitzu",
                        model = "Hakuchou Drag",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "hexer",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 16000,
                        make = "LCC",
                        model = "Hexer",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "innovation",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 33500,
                        make = "LLC",
                        model = "Innovation",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "lectro",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 28000,
                        make = "Principe",
                        model = "Lectro",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "manchez",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 8300,
                        make = "Maibatsu",
                        model = "Manchez",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "nemesis",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 20000,
                        make = "Principe",
                        model = "Nemesis",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "nightblade",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 23000,
                        make = "WMC",
                        model = "Nightblade",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "pcj",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 15000,
                        make = "Shitzu",
                        model = "PCJ-600",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "ratbike",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 3000,
                        make = "Western",
                        model = "Rat Bike",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "ruffian",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 25000,
                        make = "Pegassi",
                        model = "Ruffian",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "sanchez",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 5300,
                        make = "Maibatsu",
                        model = "Sanchez Livery",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "sanchez2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 5300,
                        make = "Maibatsu",
                        model = "Sanchez",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "sanctus",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 35000,
                        make = "LCC",
                        model = "Sanctus",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "shotaro",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 320000,
                        make = "Nagasaki",
                        model = "Shotaro",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "sovereign",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 8000,
                        make = "WMC",
                        model = "Sovereign",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "stryder",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 50000,
                        make = "Nagasaki",
                        model = "Stryder",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "thrust",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 22000,
                        make = "Dinka",
                        model = "Thrust",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "vader",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 7200,
                        make = "Shitzu",
                        model = "Vader",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "vindicator",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 19000,
                        make = "Dinka",
                        model = "Vindicator",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "vortex",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 31000,
                        make = "Pegassi",
                        model = "Vortex",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "wolfsbane",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 14000,
                        make = "Western",
                        model = "Wolfsbane",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "zombiea",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 28000,
                        make = "Western",
                        model = "Zombie Bobber",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "zombieb",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 27000,
                        make = "Western",
                        model = "Zombie Chopper",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "manchez2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 14000,
                        make = "Maibatsu",
                        model = "Manchez Scout",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "shinobi",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 25000,
                        make = "Nagasaki",
                        model = "Shinobi",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "reever",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 25000,
                        make = "Western",
                        model = "Reever",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "manchez3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 15000,
                        make = "Maibatsu",
                        model = "Manchez Scout Classic",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "powersurge",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "M",
                        price = 7000,
                        make = "Western",
                        model = "Powersurge",
                        category = "motorcycles"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "bfinjection",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 9000,
                        make = "Annis",
                        model = "Bf Injection",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "bifta",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 15500,
                        make = "Annis",
                        model = "Bifta",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "blazer",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 7500,
                        make = "Annis",
                        model = "Blazer",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "blazer2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 7000,
                        make = "Nagasaki",
                        model = "Blazer Lifeguard",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "blazer3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 7000,
                        make = "Nagasaki",
                        model = "Blazer Hot Rod",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "blazer4",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 9250,
                        make = "Annis",
                        model = "Blazer Sport",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "blazer5",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 40000,
                        make = "Nagasaki",
                        model = "Blazer Aqua",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "brawler",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 40000,
                        make = "Annis",
                        model = "Brawler",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "caracara",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 60000,
                        make = "Vapid",
                        model = "Caracara",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "caracara2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 80000,
                        make = "Vapid",
                        model = "Caracara 4x4",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dubsta3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 34000,
                        make = "Annis",
                        model = "Dubsta 6x6",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "dune",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 14000,
                        make = "Annis",
                        model = "Dune Buggy",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "everon",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 60000,
                        make = "Karin",
                        model = "Everon",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "freecrawler",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 24000,
                        make = "Canis",
                        model = "Freecrawler",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "hellion",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 38000,
                        make = "Annis",
                        model = "Hellion",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "kalahari",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 14000,
                        make = "Canis",
                        model = "Kalahari",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "kamacho",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 50000,
                        make = "Canis",
                        model = "Kamacho",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "mesa3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 400000,
                        make = "Canis",
                        model = "Mesa Merryweather",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "outlaw",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 15000,
                        make = "Nagasaki",
                        model = "Outlaw",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "rancherxl",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 24000,
                        make = "Declasse",
                        model = "Rancher XL",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "rebel2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 20000,
                        make = "Vapid",
                        model = "Rebel",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "riata",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 380000,
                        make = "Vapid",
                        model = "Riata",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "sandking",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 25000,
                        make = "Vapid",
                        model = "Sandking XL",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "sandking2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 38000,
                        make = "Vapid",
                        model = "Sandking SWB",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "trophytruck",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 60000,
                        make = "Vapid",
                        model = "Trophy Truck",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "trophytruck2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 80000,
                        make = "Vapid",
                        model = "Desert Raid",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "vagrant",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 50000,
                        make = "Maxwell",
                        model = "Vagrant",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "verus",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 20000,
                        make = "Dinka",
                        model = "Verus",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "winky",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 10000,
                        make = "Vapid",
                        model = "Winky",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "yosemite3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 425000,
                        make = "Declasse",
                        model = "Yosemite Rancher",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "mesa",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 12000,
                        make = "Canis",
                        model = "Mesa",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "ratel",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 199000,
                        make = "Vapid",
                        model = "Ratel",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "l35",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 167000,
                        make = "Declasse",
                        model = "Walton L35",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "monstrociti",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 48000,
                        make = "Maibatsu",
                        model = "MonstroCiti",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "draugur",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 99000,
                        make = "Declasse",
                        model = "Draugur",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "terminus",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 187750,
                        make = "Canis",
                        model = "Terminus",
                        category = "offroad"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "sadler",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 20000,
                        make = "Vapid",
                        model = "Sadler",
                        category = "utility"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "bison",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 18000,
                        make = "Bravado",
                        model = "Bison",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "bobcatxl",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 13500,
                        make = "Vapid",
                        model = "Bobcat XL Open",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "burrito3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 4000,
                        make = "Declasse",
                        model = "Burrito",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "gburrito2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 11500,
                        make = "Declasse",
                        model = "Burrito Custom",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "rumpo",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 9000,
                        make = "Bravado",
                        model = "Rumpo",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "journey",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 6500,
                        make = "Zirconium",
                        model = "Journey",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "minivan",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 7000,
                        make = "Vapid",
                        model = "Minivan",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "minivan2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 10000,
                        make = "Vapid",
                        model = "Minivan Custom",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "paradise",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 9000,
                        make = "Bravado",
                        model = "Paradise",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "rumpo3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 19500,
                        make = "Bravado",
                        model = "Rumpo Custom",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "speedo",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 10000,
                        make = "Vapid",
                        model = "Speedo",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "speedo4",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 15000,
                        make = "Vapid",
                        model = "Speedo Custom",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "surfer",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 9000,
                        make = "BF",
                        model = "Surfer",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "youga3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 15000,
                        make = "Bravado",
                        model = "Youga Classic 4x4",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "youga",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 8000,
                        make = "Bravado",
                        model = "Youga",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "youga2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 14500,
                        make = "Bravado",
                        model = "Youga Classic",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "youga4",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 85000,
                        make = "Bravado",
                        model = "Youga Custom",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "moonbeam",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 13000,
                        make = "Declasse",
                        model = "Moonbeam",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "moonbeam2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 15000,
                        make = "Declasse",
                        model = "Moonbeam Custom",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "journey2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 7000,
                        make = "Zirconium",
                        model = "Journey II",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "surfer3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 15000,
                        make = "BF",
                        model = "Surfer Custom",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "speedo5",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 238000,
                        make = "Vapid",
                        model = "Speedo Custom",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "mule2",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 40000,
                        make = "Maibatsu",
                        model = "Mule",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "mule3",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 40000,
                        make = "Maibatsu",
                        model = "Mule",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "taco",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 45000,
                        make = "Brute",
                        model = "Taco Truck",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                {
                    vehicle = "boxville6",
                    quantity = 100,
                    dealership = "pdm",
                    data = {
                        class = "B",
                        price = 47500,
                        make = "Brute",
                        model = "Boxville (LSDS)",
                        category = "van"
                    },
                    lastStocked = os.time(),
                },
                
        }
        
        Default:Add("dealership_vehicles", 1630877439, vehicleStockData)
        
        -- Create vehicle definitions from stock data
        if Dealerships then
            for _, stockItem in ipairs(vehicleStockData) do
                if stockItem.dealership and stockItem.vehicle and stockItem.data then
                    Dealerships.VehicleDefinitions:Add(
                        stockItem.dealership,
                        stockItem.vehicle,
                        stockItem.modelType or 'automobile',
                        stockItem.data
                    )
                end
            end
        end
    end
end
