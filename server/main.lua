--------------------------------------------
-- VARIABLES
--------------------------------------------
local evidenceList = {}
local casingEvidence={}
local bulletholeEvidence={}
local vehicleFragmentEvidence={}
local bloodEvidence={}
local footprintEvidence={}

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
        degrade = 0
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
    --elseif type == 'footprint' then
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
    elseif type == 'footprint' then
        footprintEvidence[evidenceId] = evidence
    end
end)


--------------------------------------------
-- DEGRADE
--------------------------------------------
CreateThread(function ()
    while true do
        local LoadFile = LoadResourceFile(GetCurrentResourceName(), "./server/evidence.json")
        if LoadFile then
            local evidenceL = json.decode(LoadFile)
            for evidenceId, evidence in pairs(evidenceL) do
                if not evidence.degrade then evidence.degrade = 0 end
                evidence.degrade = evidence.degrade + 1

                if evidence.degrade == 100 then
                    evidence = nil
                end

                if type == 'casing' then
                    casingEvidence[evidenceId] = evidence
                elseif type == 'bullethole' then
                    bulletholeEvidence[evidenceId] = evidence
                elseif type == 'vehicleFragment' then
                    vehicleFragmentEvidence[evidenceId] = evidence
                elseif type == 'blood' then
                    bloodEvidence[evidenceId] = evidence
                elseif type == 'footprint' then
                    footprintEvidence[evidenceId] = evidence
                end
            end
            evidenceList = evidenceL
            SaveResourceFile(GetCurrentResourceName(), "server/evidence.json", json.encode(evidenceList, { indent = true }), -1)

            TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', -1, 'casing', casingEvidence)
            TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', -1, 'bullethole', bulletholeEvidence)
            TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', -1, 'vehicleFragment', vehicleFragmentEvidence)
            TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', -1, 'blood', bloodEvidence)
            TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', -1, 'footprint', footprintEvidence)
        end
        Wait(Config.DegradeTime * 60000)
    end
end)