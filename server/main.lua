--------------------------------------------
-- VARIABLES
--------------------------------------------
local evidenceList = {}
local casingEvidence={}
local bulletholeEvidence={}
local vehicleFragmentEvidence={}

--------------------------------------------
-- LOCAL FUNCTIONS
--------------------------------------------
local function saveEvidenceList()
    local LoadFile = LoadResourceFile(GetCurrentResourceName(), "./server/evidence.json")
    if LoadFile then
        SaveResourceFile(GetCurrentResourceName(), "server/evidence.json", json.encode(evidenceList, { indent = true }), -1)
    end
end

local function generateEvidenceId()
    local evidenceId = math.random(1000, 9999)
    while evidenceList[evidenceId] do
        evidenceId = math.random(1000, 9999)
    end
    return evidenceId
end
--------------------------------------------
-- FUNCTIONS
--------------------------------------------

--------------------------------------------
-- EVENTS
--------------------------------------------
RegisterNetEvent(GetCurrentResourceName()..':server:CreateEvidence',function (type, weapon, coords, currentTime, pedcoords, heading, entityHit)
    local source = source
    local evidence = {
        type = type,
        coords = coords,
        timestamp = currentTime,
        identifier = getPlayerIdentifier(source),
    }

    if type == 'casing' then
        evidence.casingType = weapon.ammo
        if weapon.metadata and weapon.metadata ~= '' then
            evidence.serial = weapon.metadata.serial
        end
    elseif type == 'bullethole' then
        evidence.bulletType = weapon.ammo
        evidence.pedCoords = vector4(pedcoords.x,pedcoords.y,pedcoords.z,heading)
        if weapon.metadata and weapon.metadata ~= '' then
            evidence.serial = weapon.metadata.serial
        end
    elseif type == 'vehicleFragment' then
        evidence.bulletType = weapon.ammo
        evidence.pedCoords = vector4(pedcoords.x,pedcoords.y,pedcoords.z,heading)
        if weapon.metadata and weapon.metadata ~= '' then
            evidence.serial = weapon.metadata.serial
        end
        local vehInfo = lib.callback.await(GetCurrentResourceName()..':GetVehicleInfo', source, entityHit)
        if vehInfo then
            evidence.color = vehInfo.color
            evidence.model = vehInfo.model
            evidence.modelHash = vehInfo.modelHash
        end

    end

    local evidenceId = generateEvidenceId()
    evidenceList[evidenceId] = evidence
    saveEvidenceList()
    --casingEvidence[evidenceId] = evidence
    --print(json.encode(evidence))
    TriggerClientEvent(GetCurrentResourceName()..':client:CreateEvidence', -1, evidenceId, evidence)

    if type == 'casing' then
        casingEvidence[evidenceId] = evidence
    elseif type == 'bullethole' then
        bulletholeEvidence[evidenceId] = evidence
    elseif type == 'vehicleFragment' then
        vehicleFragmentEvidence[evidenceId] = evidence
    end
end)