--------------------------------------------
-- VARIABLES
--------------------------------------------
local evidenceList = {}
local casingEvidence={}
local bulletholeEvidence={}
local vehicleFragmentEvidence={}
local bloodEvidence={}
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
RegisterNetEvent(GetCurrentResourceName()..':server:CreateEvidence',function (type, data)
    local source = source
    local evidence = {
        type = type,
        coords = data.evidence_coords,
        timestamp = data.currentTime,
        identifier = getPlayerIdentifier(source),
    }

    if type == 'casing' then
        evidence.casingType = data.weapon.ammo
        if data.weapon.metadata and data.weapon.metadata ~= '' then
            evidence.serial = data.weapon.metadata.serial
        end
    elseif type == 'bullethole' then
        evidence.bulletType = data.weapon.ammo
        evidence.pedCoords = vector4(data.pedcoords.x,data.pedcoords.y,data.pedcoords.z,data.heading)
        if data.weapon.metadata and data.weapon.metadata ~= '' then
            evidence.serial = data.weapon.metadata.serial
        end
    elseif type == 'vehicleFragment' then
        evidence.bulletType = data.weapon.ammo
        evidence.pedCoords = vector4(data.pedcoords.x,data.pedcoords.y,data.pedcoords.z,data.heading)
        if data.weapon.metadata and data.weapon.metadata ~= '' then
            evidence.serial = data.weapon.metadata.serial
        end
        local vehInfo = lib.callback.await(GetCurrentResourceName()..':GetVehicleInfo', source, data.entityHit)
        if vehInfo then
            evidence.color = vehInfo.color
            evidence.model = vehInfo.model
            evidence.modelHash = vehInfo.modelHash
        end
    elseif type == 'blood' then
        evidence.bloodType = data.bloodType
        evidence.melee = data.weapon.melee
        if data.weapon.metadata and data.weapon.metadata ~= '' then
            evidence.serial = data.weapon.metadata.serial
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
    elseif type == 'blood' then
        bloodEvidence[evidenceId] = evidence
    end
end)