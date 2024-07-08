--------------------------------------------
-- VARIABLES
--------------------------------------------
local timer = {}
local EvidenceDelay = {
    Evidence = 250,
    Blood = 250
}

local casingEvidence = {}
local bulletholeEvidence = {}
local casingEvidence = {}

PlayerData = {
    characterName = '',
    identifier = nil,
    source = nil,
    job = {
        onduty = true,
        grade = {
            level = 0,
            name = "unemployed"
        },
        name = "unemployed",
        isboss = false,
        type = "none",
        label = "Civilian"
    }
}
--------------------------------------------
-- LOCAL FUNCTIONS
--------------------------------------------
local function DrawMarkerEnt(coords)
    CreateThread(function()
        while true do
            DrawMarker(28, coords.x, coords.y, coords.z,0.0, 0.0, 0.0,0.0, 0.0, 0.0,
                1.0, 1.0, 1.0,
                0, 171, 255,75,
                false,false,2,false,0, 0, 0)

            Wait(1)
        end
    end)
end
local function DrawMarkerEvidence(coords)
    CreateThread(function()
        while true do
            DrawMarker(28, coords.x, coords.y, coords.z,0.0, 0.0, 0.0,0.0, 0.0, 0.0,
                0.3, 0.3, 0.3,
                255, 0, 0,75,
                false,false,2,false,0, 0, 0)

            Wait(1)
        end
    end)
end

local function WaitEvidence(type, func, ...)
    if not EvidenceDelay[type] then return end

    if not timer[type] then
        timer[type] = true
        func(...)
        Wait(EvidenceDelay[type])
        timer[type] = false
    end
end

local function CreateCasingEvidence(weaponUsed, ped, currentTime)
    if IsPedSwimming(ped) then return end

    local randX = math.random() + math.random(-1, 1)
    local randY = math.random() + math.random(-1, 1)
    local coords = GetOffsetFromEntityInWorldCoords(ped, randX, randY, 0)
    local _, groundz = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, true)
    coords = vector3(coords.x, coords.y, groundz)

    local data = {
        weapon = weaponUsed,
        evidence_coords = coords,
        currentTime = currentTime
    }
    TriggerServerEvent(GetCurrentResourceName()..':server:CreateEvidence', 'casing', data)

    DrawMarkerEvidence(coords)
end

local function CreateBulletHoleEvidence(weaponUsed, raycastcoords, pedcoords, heading, currentTime, entityHit)
    if raycastcoords then
        if GetEntityType(entityHit) == 2 then
            local _, groundz = GetGroundZFor_3dCoord(raycastcoords.x, raycastcoords.y, raycastcoords.z, true)
            local coords = vector3(raycastcoords.x, raycastcoords.y, groundz)
            local data = {
                weapon = weaponUsed,
                evidence_coords = coords,
                currentTime = currentTime,
                pedcoords = pedcoords,
                heading = heading,
                entityHit = NetworkGetNetworkIdFromEntity(entityHit)
            }
            TriggerServerEvent(GetCurrentResourceName()..':server:CreateEvidence', 'vehicleFragment', data)
            DrawMarkerEvidence(coords)
        elseif GetEntityType(entityHit) == 3 then
            local data = {
                weapon = weaponUsed,
                evidence_coords = raycastcoords,
                currentTime = currentTime,
                pedcoords = pedcoords,
                heading = heading
            }
            TriggerServerEvent(GetCurrentResourceName()..':server:CreateEvidence', 'bullethole', data)
            DrawMarkerEvidence(raycastcoords)
        end
    end
end

local function CreateBloodEvidence(weaponUsed, victimCoords, pedcoords, currentTime, entityHit)
    if victimCoords then
        local _, groundz = GetGroundZFor_3dCoord(victimCoords.x, victimCoords.y, victimCoords.z, true)
        local coords = vector3(victimCoords.x, victimCoords.y, groundz)

        local data = {
            weapon = weaponUsed,
            evidence_coords = coords,
            currentTime = currentTime,
            entityHit = NetworkGetNetworkIdFromEntity(entityHit),
            bloodType = getEntityBloodType(entityHit),
        }

        TriggerServerEvent(GetCurrentResourceName()..':server:CreateEvidence', 'blood', data)
        DrawMarkerEvidence(coords)
    end
end
--------------------------------------------
-- FUNCTIONS
--------------------------------------------
lib.callback.register(GetCurrentResourceName()..':GetVehicleInfo', function(netId)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(veh) and GetEntityType(veh) == 2 then
        local r, g, b = GetVehicleColor(veh)
        local info = {
            color = {r = r,g = g,b = b},
            model = GetEntityArchetypeName(veh),
            modelHash = GetEntityModel(veh)
        }
        return info
    end
    return nil
end)
--------------------------------------------
-- EVENTS
--------------------------------------------
RegisterNetEvent(GetCurrentResourceName()..':client:CreateEvidence', function (endevidenceId, evidence)
    if evidence.type == 'casing' then
        casingEvidence[endevidenceId] = evidence
    elseif evidence.type == 'bullethole' then
    elseif evidence.type == 'vehicleFragment' then
    end
end)

AddEventHandler('CEventGunShot', function(entities, eventEntity, data)
    WaitEvidence('Evidence', function ()
        if eventEntity == cache.ped then
            if PlayerData.job.name == Config.PoliceJob and not Config.PoliceEvidence then return end

            if IsPedShooting(eventEntity) then
                local pedcoords = GetEntityCoords(eventEntity)
                local heading = GetEntityHeading(eventEntity)
                local hit, entityHit, raycastcoords = lib.raycast.cam(511, 4, 1000)
                local weaponUsed = exports.ox_inventory:getCurrentWeapon()
                if not Config.WhitelistWeapon[weaponUsed.hash] then
                    local currentTime = GetGameTimer()

                    DrawMarkerEnt(raycastcoords)
                    CreateCasingEvidence(weaponUsed, eventEntity, currentTime)
                    CreateBulletHoleEvidence(weaponUsed, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b)
                end
            end
        end
    end)    
end)

AddEventHandler('CEventGunShotBulletImpact', function(entities, eventEntity, data)
    --print('CEventGunShotBulletImpact',json.encode(entities), eventEntity, json.encode(data))
end)

AddEventHandler('gameEventTriggered',function(name,args)
    if name == 'CEventNetworkEntityDamage' then
        WaitEvidence('Blood', function ()
            local victim, attacker, victimDied, weaponHash, isMelee = args[1], args[2], args[6], args[7], args[12]
            if attacker == cache.ped then
                if IsPedAPlayer(victim) or Config.BloodNPC then
                    local victimCoords = GetEntityCoords(victim)
                    local weaponUsed = exports.ox_inventory:getCurrentWeapon()
                    if not Config.WhitelistWeapon[weaponUsed.hash] then
                        local currentTime = GetGameTimer()
                        CreateBloodEvidence(weaponUsed, victimCoords, pedcoords, currentTime, victim)
                    end
                end
            end
        end)
    end
end)