lib.locale(Config.Lang)
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
    SaveResourceFile(GetCurrentResourceName(), "server/evidence.json", json.encode(evidenceList, { indent = true }), -1)
end

local function loadEvidenceList()
    local LoadFile = LoadResourceFile(GetCurrentResourceName(), "./server/evidence.json")
    if LoadFile and LoadFile~=''  then
        local evidenceL = lib.table.deepclone(json.decode(LoadFile))
            if evidenceL then
                for evidenceId, evidence in pairs(evidenceL) do
                    local evidenceType = evidence.type
                    if evidenceType == 'casing' then
                        casingEvidence[evidenceId] = evidence
                    elseif evidenceType == 'bullethole' then
                        bulletholeEvidence[evidenceId] = evidence
                    elseif evidenceType == 'vehicleFragment' then
                        vehicleFragmentEvidence[evidenceId] = evidence
                    elseif evidenceType == 'blood' then
                        bloodEvidence[evidenceId] = evidence
                    elseif evidenceType == 'footprint' then
                        footprintEvidence[evidenceId] = evidence
                    end
                end

                evidenceList = evidenceL

                TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', -1, 'casing', casingEvidence)
                TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', -1, 'bullethole', bulletholeEvidence)
                TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', -1, 'vehicleFragment', vehicleFragmentEvidence)
                TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', -1, 'blood', bloodEvidence)
                TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', -1, 'footprint', footprintEvidence)
            end
    end
end
loadEvidenceList()

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
    GiveItem(source,Config.photoItem, 1, {url=url, date = os.date('%Y/%m/%d %H:%M:%S'), identification = getPlayerIdentifier(source), description = os.date('%Y/%m/%d %H:%M:%S')})
end)

lib.callback.register(GetCurrentResourceName()..':server:CheckHasItem', function(source, typeEvidence)
    return HasItems(source, Config.EvidenceCollect[typeEvidence].itemNeed)
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

RegisterNetEvent(GetCurrentResourceName()..':server:CreateEvidence',function (evidenceType, data)
    local source = source
    local evidence = {
        type = evidenceType,
        coords = data.evidence_coords,
        timestamp = data.currentTime,
        identifier = getPlayerIdentifier(source),
        degrade = 0
    }

    if evidenceType == 'casing' then
        evidence.casingType = data.weapon.ammo
        if data.weapon.metadata and data.weapon.metadata ~= '' then
            evidence.serial = data.weapon.metadata.serial
        end
    elseif evidenceType == 'bullethole' then
        evidence.bulletType = data.weapon.ammo
        evidence.pedCoords = vector4(data.pedcoords.x,data.pedcoords.y,data.pedcoords.z,data.heading)
        if data.weapon.metadata and data.weapon.metadata ~= '' then
            evidence.serial = data.weapon.metadata.serial
        end
    elseif evidenceType == 'vehicleFragment' then
        evidence.bulletType = data.weapon.ammo
        evidence.pedCoords = vector4(data.pedcoords.x,data.pedcoords.y,data.pedcoords.z,data.heading)
        if data.weapon.metadata and data.weapon.metadata ~= '' then
            evidence.serial = data.weapon.metadata.serial
        end
        local vehInfo = lib.callback.await(GetCurrentResourceName()..':client:GetVehicleInfo', source, data.entityHit)
        if vehInfo then
            evidence.color = vehInfo.color
            evidence.model = vehInfo.model
            evidence.modelHash = vehInfo.modelHash
        end
    elseif evidenceType == 'blood' then
        evidence.bloodType = data.bloodType
        evidence.melee = data.weapon.melee==0 and true or false
        evidence.victimIdentifier = getPlayerIdentifier(data.entityHitSource)
        if data.weapon.metadata and data.weapon.metadata ~= '' then
            evidence.serial = data.weapon.metadata.serial
        end
    --elseif evidenceType == 'footprint' then
    end

    local evidenceId = generateEvidenceId()
    evidenceList[evidenceId] = evidence
    saveEvidenceList()
    TriggerClientEvent(GetCurrentResourceName()..':client:CreateEvidence', -1, evidenceId, evidence)

    if evidenceType == 'casing' then
        casingEvidence[evidenceId] = evidence
    elseif evidenceType == 'bullethole' then
        bulletholeEvidence[evidenceId] = evidence
    elseif evidenceType == 'vehicleFragment' then
        vehicleFragmentEvidence[evidenceId] = evidence
    elseif evidenceType == 'blood' then
        bloodEvidence[evidenceId] = evidence
    elseif evidenceType == 'footprint' then
        footprintEvidence[evidenceId] = evidence
    end
end)

RegisterNetEvent(GetCurrentResourceName()..':server:RequestEvidences',function (evidenceType, data)
    local source = source
    TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', source, 'casing', casingEvidence)
    TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', source, 'bullethole', bulletholeEvidence)
    TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', source, 'vehicleFragment', vehicleFragmentEvidence)
    TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', source, 'blood', bloodEvidence)
    TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', source, 'footprint', footprintEvidence)
end)

RegisterNetEvent(GetCurrentResourceName()..':server:CollectEvidence',function (evidenceId)
    local source = source
    if evidenceList[evidenceId] then
        local evidence = evidenceList[evidenceId]
        RemoveItem(source, Config.EvidenceCollect[evidence.type].itemNeed, 1)

        local ableToCollect = math.random(0,100) > evidence.degrade

        if ableToCollect then
            local metadata = {
                coords = evidence.coords,
                timestamp = evidence.timestamp,
                identifier = evidence.identifier,
                casing_type = evidence.casingType,
                weapon_serial = evidence.serial,
                bullet_type = evidence.bulletType,
                color = evidence.color,
                model = evidence.model,
                model_hash = evidence.modelHash,
                blood_type = evidence.bloodType,
                victim_identifier = evidence.victimIdentifier,
                melee = evidence.melee
            }
            GiveItem(source, Config.EvidenceCollect[evidence.type].itemReceive, 1, metadata)
        else
            lib.callback.await(GetCurrentResourceName()..':client:Notify', source, 'error', locale('nofitication.cantCollectTitle'), locale('nofitication.cantCollectDesc'))
        end

        evidenceList[evidenceId] = nil
        saveEvidenceList()
        if evidence.type == 'casing' then
            casingEvidence[evidenceId] = nil
            TriggerClientEvent(GetCurrentResourceName()..':client:DeleteEvidence', -1, 'casing', evidenceId)
        elseif evidence.type == 'bullethole' then
            bulletholeEvidence[evidenceId] = nil
            TriggerClientEvent(GetCurrentResourceName()..':client:DeleteEvidence', -1, 'bullethole', evidenceId)
        elseif evidence.type == 'vehicleFragment' then
            vehicleFragmentEvidence[evidenceId] = nil
            TriggerClientEvent(GetCurrentResourceName()..':client:DeleteEvidence', -1, 'vehicleFragment', evidenceId)
        elseif evidence.type == 'blood' then
            bloodEvidence[evidenceId] = nil
            TriggerClientEvent(GetCurrentResourceName()..':client:DeleteEvidence', -1, 'blood', evidenceId)
        elseif evidence.type == 'footprint' then
            footprintEvidence[evidenceId] = nil
            TriggerClientEvent(GetCurrentResourceName()..':client:DeleteEvidence', -1, 'footprint', evidenceId)
        end
    end
end)

RegisterNetEvent(GetCurrentResourceName()..':server:AddFingerprint',function()
    local source = source
    local identifier = getPlayerIdentifier(source)
    local weapon = exports.ox_inventory:GetCurrentWeapon(source)
    if weapon then
        local slot = weapon.slot
        local item_data = exports.ox_inventory:GetSlot(source, slot)
        local metadata = item_data.metadata and item_data.metadata or {}
        if not metadata.fingerprint then metadata.fingerprint = {} end
        if not lib.table.contains(metadata.fingerprint, identifier) then
            table.insert(metadata.fingerprint, identifier)
            exports.ox_inventory:SetMetadata(source, slot, metadata)
        end
    end
end)
--------------------------------------------
-- DEGRADE
--------------------------------------------
CreateThread(function ()
    while true do
        Wait(Config.DegradeTime * 60000)
        local LoadFile = LoadResourceFile(GetCurrentResourceName(), "./server/evidence.json")
        if LoadFile then
            local evidenceL = json.decode(LoadFile)
            if evidenceL then
                for evidenceId, evidence in pairs(evidenceL) do
                    local evidenceType = evidence.type
                    if not evidence.degrade then evidence.degrade = 0 end
                    evidence.degrade = evidence.degrade + 1

                    if evidence.degrade >= 100 then
                        evidence = nil
                    end

                    if evidenceType == 'casing' then
                        casingEvidence[evidenceId] = evidence
                    elseif evidenceType == 'bullethole' then
                        bulletholeEvidence[evidenceId] = evidence
                    elseif evidenceType == 'vehicleFragment' then
                        vehicleFragmentEvidence[evidenceId] = evidence
                    elseif evidenceType == 'blood' then
                        bloodEvidence[evidenceId] = evidence
                    elseif evidenceType == 'footprint' then
                        footprintEvidence[evidenceId] = evidence
                    end
                    evidenceL[evidenceId] = evidence
                end
                evidenceList = evidenceL
                SaveResourceFile(GetCurrentResourceName(), "server/evidence.json", json.encode(evidenceList, { indent = true }), -1)

                TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', -1, 'casing', casingEvidence)
                TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', -1, 'bullethole', bulletholeEvidence)
                TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', -1, 'vehicleFragment', vehicleFragmentEvidence)
                TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', -1, 'blood', bloodEvidence)
                TriggerClientEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', -1, 'footprint', footprintEvidence)
            end
        end
    end
end)

--------------------------------------------
-- EXPORT
--------------------------------------------
exports('CollectFingerprint', function (source,slot)
    local source = source
    --local identifier = getPlayerIdentifier(source)
    local item = exports.ox_inventory:GetSlot(source, slot)
    if item and item.metadata and Config.EvidenceCollect.fingerprint then
        if exports.ox_inventory:GetItemCount(source, Config.EvidenceCollect.fingerprint.itemNeed)>0 then
            lib.callback.await(GetCurrentResourceName()..':client:ProgressCircle', source, locale('collectFingerprint'), Config.AnimCollect.fingerprint.dict, Config.AnimCollect.fingerprint.clip)

            local ableToCollect = true
            if #item.metadata.fingerprint >= Config.FingerprintQuality.lowQuality then
                ableToCollect = math.random(0,100) > 10
            elseif #item.metadata.fingerprint >= Config.FingerprintQuality.mediumQuality then
                ableToCollect = math.random(0,100) > 50
            end

            if ableToCollect then
                for _, identifier in pairs(item.metadata.fingerprint) do
                    if exports.ox_inventory:GetItemCount(source, Config.EvidenceCollect.fingerprint.itemNeed)>0 then
                        RemoveItem(source, Config.EvidenceCollect.fingerprint.itemNeed, 1)
                        local metadata = {
                            timestamp = GetGameTimer(),
                            identifier = identifier,
                            weapon_serial = item.metadata.serial,
                            --bullet_type = evidence.bulletType,
                            --melee = evidence.melee
                        }
                        GiveItem(source, Config.EvidenceCollect.fingerprint.itemReceive, 1, metadata)
                    else
                        RemoveItem(source, Config.EvidenceCollect.fingerprint.itemNeed, 1)
                        lib.callback.await(GetCurrentResourceName()..':client:Notify', source, 'error', locale('nofitication.missingItemCollectTitle'), locale('nofitication.missingItemCollectDesc'))
                    end
                end

            else
                lib.callback.await(GetCurrentResourceName()..':client:Notify', source, 'error', locale('nofitication.cantCollectTitle'), locale('nofitication.cantCollectDesc'))
            end
        end
    end

end)