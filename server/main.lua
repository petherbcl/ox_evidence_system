--------------------------------------------
-- VARIABLES
--------------------------------------------
local evidenceList = {}
local casingEvidence={}
local bulletholeEvidence={}
local vehicleFragmentEvidence={}
local bloodEvidence={}

CameraEntitys = {}
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
lib.callback.register(GetCurrentResourceName()..':server:SpawnProp', function(source, propHash, cds)
    local object = CreateObjectNoOffset(propHash,cds.x,cds.y,cds.z,false,true,false)
    while not DoesEntityExist(object) do
        Wait(50)
    end
    CameraEntitys[source] = NetworkGetNetworkIdFromEntity(object)
    SetEntityDistanceCullingRadius(object,999999999.0)
    return CameraEntitys[source]
end)

lib.callback.register(GetCurrentResourceName()..':server:DeleteCam', function(source)
    DeleteEntity(NetworkGetEntityFromNetworkId(CameraEntitys[source]))
    CameraEntitys[source] = nil
end)

lib.callback.register(GetCurrentResourceName()..':server:CreatePhotoItem', function(source, url)
    local source = source
    exports.ox_inventory:AddItem(source, Config.photoItem, 1, {url=url, date = os.date('%Y/%m/%d %H:%M:%S'), identification = getPlayerIdentifier(source), description = 'Date: '..os.date('%Y/%m/%d %H:%M:%S')..'\nIdentification: '..getPlayerName(source)})
end)
--------------------------------------------
-- EVENTS
--------------------------------------------
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        for i, netId in pairs(CameraEntitys) do
            DeleteEntity(NetworkGetEntityFromNetworkId(netId))
            CameraEntitys[i] = nil
        end
    end
end)
AddEventHandler("playerDropped",function()
    local source = source
    if CameraEntitys[source] then
        DeleteEntity(NetworkGetEntityFromNetworkId(CameraEntitys[source]))
        CameraEntitys[source] = nil
    end
end)

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
