lib.locale(Config.Lang)
--------------------------------------------
-- VARIABLES
--------------------------------------------
local usingCam = false
local showMarker = false
local currentWeapon
local timer = {}
local EvidenceDelay = {
    Evidence = 250,
    Blood = 250,
    Ffootprint = 500,
}
local globalEvidenceList = {}
local casingEvidence = {}
local bulletholeEvidence = {}
local vehicleFragmentEvidence = {}
local bloodEvidence = {}
local footprintEvidence = {}

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


local function DrawEvidenceMarker(evidenceType, evidence)
    while not HasStreamedTextureDictLoaded(evidenceType) do
        Wait(10)
        RequestStreamedTextureDict(evidenceType, true)
    end

    SetDrawOrigin(evidence.coords.x, evidence.coords.y, evidence.coords.z, 0)
    DrawSprite(evidenceType, evidenceType, 0, 0, 0.04, 0.055, 0, 255, 255, 255, 255)
    if Config.ShowShootersLine and evidence.pedCoords then
        DrawLine(evidence.coords.x, evidence.coords.y, evidence.coords.z, evidence.pedCoords.x, evidence.pedCoords.y, evidence.pedCoords.z, 255, 0, 0, 255)
    end
end


local function WaitEvidence(evidenceType, func, ...)
    if not EvidenceDelay[evidenceType] then return end

    if not timer[evidenceType] then
        timer[evidenceType] = true
        func(...)
        Wait(EvidenceDelay[evidenceType])
        timer[evidenceType] = false
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
end

local function CreateBulletHoleEvidence(weaponUsed, raycastcoords, pedcoords, heading, currentTime, entityHit)
    if raycastcoords and #(raycastcoords - vector3(0.0,0.0,0.0)) > 1 then
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
        elseif GetEntityType(entityHit) ~= 1 then
            local data = {
                weapon = weaponUsed,
                evidence_coords = raycastcoords,
                currentTime = currentTime,
                pedcoords = pedcoords,
                heading = heading
            }
            TriggerServerEvent(GetCurrentResourceName()..':server:CreateEvidence', 'bullethole', data)
        end
    end
end

local function CreateBloodEvidence(weaponUsed, victimCoords, pedcoords, heading, currentTime, entityHit)
    if victimCoords then
        local dx = 0
        if heading <90 or heading > 270 then
            dx = math.random(50)/100
        elseif heading >90 or heading < 270 then
            dx = -1*math.random(50)/100
        end

        local dy = 0
        if heading > 0 and heading < 180 then
            dy = math.random(50)/100
        elseif heading > 180 and heading < 360 then
            dy = -1*math.random(50)/100
        end

        local _, groundz = GetGroundZFor_3dCoord(victimCoords.x+dx, victimCoords.y+dy, victimCoords.z, true)
        local coords = vector3(victimCoords.x+dx, victimCoords.y+dy, groundz)

        local data = {
            weapon = weaponUsed,
            evidence_coords = coords,
            currentTime = currentTime,
            entityHit = NetworkGetNetworkIdFromEntity(entityHit),
            bloodType = getEntityBloodType(entityHit),
        }

        TriggerServerEvent(GetCurrentResourceName()..':server:CreateEvidence', 'blood', data)
    end
end

local function CreateFfootprintEvidence(ped, pedcoords, currentTime)
    if IsPedSwimming(ped) then return end
    local _, groundz = GetGroundZFor_3dCoord(pedcoords.x, pedcoords.y, pedcoords.z, true)
    local data = {
        evidence_coords = vector3(pedcoords.x, pedcoords.y, groundz),
        currentTime = currentTime
    }
    TriggerServerEvent(GetCurrentResourceName()..':server:CreateEvidence', 'footprint', data)
end

local function ShowEvidenceMarker(evidenceType, maxDist)
    local list
    if evidenceType == 'casing' then
        list = casingEvidence
    elseif evidenceType == 'bullethole' then
        list = bulletholeEvidence
    elseif evidenceType == 'vehicleFragment' then
        list = vehicleFragmentEvidence
    elseif evidenceType == 'blood' then
        list = bloodEvidence
    elseif evidenceType == 'footprint' then
        list = footprintEvidence
    end

    if list then
        CreateThread(function()
            while showMarker do
                local pos = GetEntityCoords(PlayerPedId(), true)
                for _, evidence in pairs(list) do
                    local dist = #(pos - vector3(evidence.coords.x, evidence.coords.y, evidence.coords.z))
                    if dist < maxDist then
                        DrawEvidenceMarker(evidenceType, evidence)
                    end
                end
                Wait(0)
            end
        end)
    end
end
--------------------------------------------
-- FUNCTIONS
--------------------------------------------
lib.callback.register(GetCurrentResourceName()..':client:GetVehicleInfo', function(netId)
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

RegisterKeyMapping(GetCurrentResourceName()..'_'..Config.InteractKey, 'Interact with Evidence', "keyboard", Config.InteractKey)
RegisterCommand(GetCurrentResourceName()..'_'..Config.InteractKey, function()
    if currentWeapon and PlayerData.job.name == Config.PoliceJob and PlayerData.job.onduty then
        local canCheck = true
        if Config.PoliceShowEvidenceWeapomAim and not IsPlayerFreeAiming(PlayerId()) then
            canCheck = false
        end
        if canCheck then
            local pedCds = GetEntityCoords(PlayerPedId())
            local maxDist = 2
            local closestEvidenceId
            for endevidenceId, evidence in pairs(globalEvidenceList) do
                local distance = #(pedCds - vector3(evidence.coords.x,evidence.coords.y,evidence.coords.z))
                if distance < maxDist then
                    maxDist = distance
                    closestEvidenceId = endevidenceId
                end
            end

            if closestEvidenceId and Config.EvidenceCollect[globalEvidenceList[closestEvidenceId].type] then
                local evidence = globalEvidenceList[closestEvidenceId]
                local qualityColor = '#74B816'
                if evidence.degrade >= Config.DegradeLevel.lowQuality then
                    qualityColor = '#C92A2A'
                elseif evidence.degrade >= Config.DegradeLevel.mediumQuality then
                    qualityColor = '#FF922B'
                end

                lib.registerContext({
                    id = 'evidence_'..evidence.type,
                    title = locale('evidence')..' '..locale(evidence.type),
                    options = {
                        {title = locale('evidenceQuality'), readOnly = true, progress = 100-evidence.degrade, colorScheme = qualityColor},
                        {title = locale('collectEvidence'), arrow = true, onSelect = function ()
                            if lib.callback.await(GetCurrentResourceName()..':server:CheckHasItem', nil, evidence.type) then
                                TriggerServerEvent(GetCurrentResourceName()..':server:CollectEvidence', closestEvidenceId)

                                lib.progressCircle({
                                    duration = 10000,
                                    label = locale('collectEvidence'),
                                    useWhileDead = false,
                                    canCancel = false,
                                    disable = {
                                        move = true,
                                    },
                                    anim = {
                                        dict = 'amb@medic@standing@tendtodead@idle_a',
                                        clip = 'idle_a',
                                        flag = 1
                                    },
                                })
                            else
                                lib.notify({
                                    title = locale('nofitication.missingItemCollectTitle'),
                                    description = locale('nofitication.missingItemCollectDesc', exports.ox_inventory:Items(Config.EvidenceCollect[evidence.type].itemNeed).label),
                                    type = 'error'
                                })
                            end
                            
                        end},
                    },
                })
                lib.showContext('evidence_'..evidence.type)
            end
        end
    end
end)
lib.callback.register(GetCurrentResourceName()..':client:Notify', function(type, title, description)
    lib.notify({
        title = title,
        description = description,
        type = type
    })
end)

--------------------------------------------
-- EVENTS
--------------------------------------------
RegisterNetEvent(GetCurrentResourceName()..':client:CreateEvidence', function (endevidenceId, evidence)
    if evidence.type == 'casing' then
        casingEvidence[endevidenceId] = evidence
    elseif evidence.type == 'bullethole' then
        bulletholeEvidence[endevidenceId] = evidence
    elseif evidence.type == 'vehicleFragment' then
        vehicleFragmentEvidence[endevidenceId] = evidence
    elseif evidence.type == 'blood' then
        bloodEvidence[endevidenceId] = evidence
    elseif evidence.type == 'footprint' then
        footprintEvidence[endevidenceId] = evidence
    end
    globalEvidenceList[endevidenceId] = evidence
end)

RegisterNetEvent(GetCurrentResourceName()..':client:UpdateEvidenceListType', function (evidenceType, evidenceList)
    if evidenceType == 'casing' then
        casingEvidence = evidenceList
    elseif evidenceType == 'bullethole' then
        bulletholeEvidence = evidenceList
    elseif evidenceType == 'vehicleFragment' then
        vehicleFragmentEvidence = evidenceList
    elseif evidenceType == 'blood' then
        bloodEvidence = evidenceList
    elseif evidenceType == 'footprint' then
        footprintEvidence = evidenceList
    end

    for endevidenceId, evidence in pairs(evidenceList) do
        globalEvidenceList[endevidenceId] = evidence
    end
end)

RegisterNetEvent(GetCurrentResourceName()..':client:DeleteEvidence', function (evidenceType, endevidenceId)
    if evidenceType == 'casing' then
        casingEvidence[endevidenceId] = nil
    elseif evidenceType == 'bullethole' then
        bulletholeEvidence[endevidenceId] = nil
    elseif evidenceType == 'vehicleFragment' then
        vehicleFragmentEvidence[endevidenceId] = nil
    elseif evidenceType == 'blood' then
        bloodEvidence[endevidenceId] = nil
    elseif evidenceType == 'footprint' then
        footprintEvidence[endevidenceId] = nil
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
                    --DrawMarkerEnt(raycastcoords)
                    CreateCasingEvidence(weaponUsed, eventEntity, currentTime)
                    CreateBulletHoleEvidence(weaponUsed, raycastcoords, pedcoords, heading, currentTime, entityHit)
                end
            end
        end
    end)    
end)

if Config.AllowFootprint then
    AddEventHandler('CEventFootStepHeard', function(witnesses, eventEntity)
        WaitEvidence('Ffootprint', function ()
            if eventEntity == cache.ped then
                if PlayerData.job.name == Config.PoliceJob and not Config.PoliceEvidence then return end
                local pedcoords = GetEntityCoords(eventEntity)
                local currentTime = GetGameTimer()
                CreateFfootprintEvidence(eventEntity, pedcoords, currentTime)
            end
        end)
    end)
end

AddEventHandler('gameEventTriggered',function(name,args)
    if name == 'CEventNetworkEntityDamage' then
        WaitEvidence('Blood', function ()
            local victim, attacker, victimDied, weaponHash, isMelee = args[1], args[2], args[6], args[7], args[12]
            if attacker == cache.ped then
                if IsPedAPlayer(victim) or Config.BloodNPC then
                    local pedcoords = GetEntityCoords(attacker)
                    local victimCoords = GetEntityCoords(victim)
                    local heading = GetEntityHeading(attacker)
                    local weaponUsed = exports.ox_inventory:getCurrentWeapon()
                    if weaponUsed and not Config.WhitelistWeapon[weaponUsed.hash] then
                        local currentTime = GetGameTimer()
                        CreateBloodEvidence(weaponUsed, victimCoords, pedcoords, heading, currentTime, victim)
                    end
                end
            end
        end)
    end
end)

lib.onCache('weapon', function(value)
    currentWeapon = value
    if currentWeapon then
        if PlayerData.job.name ~= Config.PoliceJob or (PlayerData.job.name == Config.PoliceJob and not Config.PoliceEvidence) then 
            TriggerServerEvent(GetCurrentResourceName()..':server:AddFingerprint')
        end
        
        if value == Config.PoliceShowEvidenceWeapom then
            currentWeapon = value
            if PlayerData.job.name == Config.PoliceJob and PlayerData.job.onduty then
                if Config.PoliceShowEvidenceWeapomAim then
                    CreateThread(function()
                        while currentWeapon do
                            if IsPlayerFreeAiming(PlayerId()) then
                                if showMarker == false then
                                    showMarker = true
                                    ShowEvidenceMarker('casing',Config.PoliceEvidenceMaxDist)
                                    ShowEvidenceMarker('bullethole',Config.PoliceEvidenceMaxDist)
                                    ShowEvidenceMarker('vehicleFragment',Config.PoliceEvidenceMaxDist)
                                    ShowEvidenceMarker('blood',Config.PoliceEvidenceMaxDist)
                                    ShowEvidenceMarker('footprint',Config.PoliceEvidenceMaxDist)
                                end
                            else
                                showMarker = false
                            end
                            Wait(100)
                        end
                    end)
                else
                    showMarker = true
                    ShowEvidenceMarker('casing',Config.PoliceEvidenceMaxDist)
                    ShowEvidenceMarker('bullethole',Config.PoliceEvidenceMaxDist)
                    ShowEvidenceMarker('vehicleFragment',Config.PoliceEvidenceMaxDist)
                    ShowEvidenceMarker('blood',Config.PoliceEvidenceMaxDist)
                    ShowEvidenceMarker('footprint',Config.PoliceEvidenceMaxDist)
                end
            end

            TriggerServerEvent(GetCurrentResourceName()..':server:AddFingerPrint')
        end
    else
        showMarker = false
    end

end)



--------------------------------------------
-- CAMERA
--------------------------------------------
local fov_max = 80.0
local fov_min = 5.0 -- max zoom level (smaller fov is more zoom)
local zoomspeed = 10.0 -- camera zoom speed
local speed_lr = 8.0 -- speed by which the camera pans left-right
local speed_ud = 8.0 -- speed by which the camera pans up-down
local fov = (fov_max+fov_min)*0.5
local zoomNui = 1

local function CheckInputRotation(cam, zoomvalue)
    local rightAxisX = GetDisabledControlNormal(0, 220)
    local rightAxisY = GetDisabledControlNormal(0, 221)
    local rotation = GetCamRot(cam, 2)
    if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        local new_z = rotation.z + rightAxisX*-1.0*(speed_ud)*(zoomvalue+0.1)
        local new_x = math.max(math.min(20.0, rotation.x + rightAxisY*-1.0*(speed_lr)*(zoomvalue+0.1)), -89.5)
        SetCamRot(cam, new_x, 0.0, new_z, 2)
        -- Moves the entities body if they are not in a vehicle (else the whole vehicle will rotate as they look around :P)
        if not IsPedSittingInAnyVehicle(PlayerPedId()) then
            SetEntityHeading(PlayerPedId(), new_z)
        end
    end
end

local function HandleZoom(cam)
    local lPed = PlayerPedId()
    if not IsPedSittingInAnyVehicle(lPed) then
        if IsControlJustPressed(0,241) then -- SCROLLWHEEL UP
            fov = math.max(fov - zoomspeed, fov_min)
            zoomNui = zoomNui * 2
        end
        if IsControlJustPressed(0,242) then -- SCROLLWHEEL DOWN	
            fov = math.min(fov + zoomspeed, fov_max)
            zoomNui = zoomNui / 2
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov-current_fov) < 0.1 then
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov)*0.05)
    else
        if IsControlJustPressed(0,17) then -- SCROLLWHEEL UP
            fov = math.max(fov - zoomspeed, fov_min)
            zoomNui = zoomNui * 2
        end
        if IsControlJustPressed(0,16) then -- SCROLLWHEEL DOWN
            fov = math.min(fov + zoomspeed, fov_max)
            zoomNui = zoomNui / 2
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov-current_fov) < 0.1 then
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov)*0.05)
    end

    if zoomNui < 0.0625 then zoomNui = 0.0625 end
    if zoomNui > 16 then zoomNui = 16 end
    SendNUIMessage({action = "updateZoom", zoom = zoomNui})
end

local function FlashLightEffect()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local lightPos = vector3(pos.x, pos.y, pos.z + 1.1)
    local lightHandle = nil
    CreateThread(function()
        local endTime = GetGameTimer() + 150
        while endTime > GetGameTimer() do
            lightHandle = DrawLightWithRangeAndShadow(lightPos.x, lightPos.y, lightPos.z, 15, 15, 15, 50.0, 10.0, 0.5, true)
            Wait(0)
        end
        if lightHandle ~= nil then
            lightHandle = nil
        end
    end)
end


local function StartCamera()
    local ped = PlayerPedId()
    local camNetId = lib.callback.await(GetCurrentResourceName()..':server:SpawnProp', nil, Config.cameraProp, GetEntityCoords(ped))
    while not DoesEntityExist(NetworkGetEntityFromNetworkId(camNetId)) do
        Wait(10)
    end
    local camProp = NetworkGetEntityFromNetworkId(camNetId)

    lib.requestAnimDict('amb@world_human_paparazzi@male@base')
    TaskPlayAnim(ped, "amb@world_human_paparazzi@male@base", "base", 2.0, 2.0, -1, 1, 0, false, false, false)
    AttachEntityToEntity(camProp, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    
    CreateThread(function ()
        local sleep = 250
        while usingCam do
            sleep = 250
            if not IsEntityPlayingAnim(ped,"amb@world_human_paparazzi@male@base", "base",3) then
                TaskPlayAnim(ped, "amb@world_human_paparazzi@male@base", "base", 2.0, 2.0, -1, 49, 0, false, false, false)
                sleep = 1
            end

            Wait(sleep)
        end
    end)

    CreateThread(function ()
        local doFlash = false
        SetTimecycleModifier("default")
        SetTimecycleModifierStrength(0.3)

        local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
        AttachCamToEntity(cam, ped, 0.0, 1.0, 0.8, true)
        SetCamRot(cam, 0.0, 0.0, GetEntityHeading(ped), 2)
        SetCamFov(cam, fov)
        RenderScriptCams(true, false, 0, true, false)

        zoomNui = 1

        if PlayerData.job.name == Config.PoliceJob and PlayerData.job.onduty then
            showMarker = true
            ShowEvidenceMarker('casing',Config.camEvidenceMaxDistance)
            ShowEvidenceMarker('bullethole',Config.camEvidenceMaxDistance)
            ShowEvidenceMarker('vehicleFragment',Config.camEvidenceMaxDistance)
            ShowEvidenceMarker('blood',Config.camEvidenceMaxDistance)
            ShowEvidenceMarker('footprint',Config.camEvidenceMaxDistance)
        end

        SendNUIMessage({action = "startCamera"})

        while usingCam and not IsEntityDead(ped) do -- and GetVehiclePedIsIn(ped) == 0 do
            if IsControlJustPressed(0, 177) then -- BACKSPACE / ESC / RIGHT MOUSE BUTTON
                usingCam = false
                showMarker = false
            elseif IsControlJustPressed(0, 38) then -- E
                doFlash = not doFlash
                SendNUIMessage({action = "setFlash", flash = doFlash})
            elseif IsControlJustPressed(1, 176) then -- ENTER / LEFT MOUSE BUTTON
                if doFlash then
                    FlashLightEffect()
                    Wait(100)
                end
                PlaySoundFrontend(-1, "Camera_Shoot", "Phone_Soundset_Franklin", false)

                exports['screenshot-basic']:requestScreenshotUpload('https://api.fivemanage.com/api/image?apiKey='..Config.FiveManageImgToken, 'image', function(data)
                    local resp = json.decode(data)
                    if resp then
                        lib.callback.await(GetCurrentResourceName()..':server:CreatePhotoItem', nil, resp.url)
                    end
                end)
                Wait(100) -- You can adjust the timing if needed
                ClearTimecycleModifier()
                usingCam = false
                showMarker = false
            end

            local zoomvalue = (1.0 / (fov_max - fov_min)) * (fov - fov_min)
            CheckInputRotation(cam, zoomvalue)
            HandleZoom(cam)
            Wait(0)
        end
        SendNUIMessage({action = "finishCamera", flash = doFlash})
        ClearTimecycleModifier()
        fov = (fov_max + fov_min) * 0.5
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(cam, false)
        SetNightvision(false)
        SetSeethrough(false)

        DetachEntity(camProp)
        lib.callback.await(GetCurrentResourceName()..':server:DeleteCam')
        ClearPedTasks(ped)

    end)
end

RegisterNetEvent(GetCurrentResourceName()..':StartCamera', function ()
    if not usingCam and not IsEntityDead(PlayerPedId()) then --and GetVehiclePedIsIn(PlayerPedId()) == 0 then
        usingCam = true
        StartCamera()
    end
end)

RegisterNetEvent(GetCurrentResourceName()..':openPhoto', function (url, description)
    SetNuiFocus(true,true)
    SendNUIMessage({action = "openPhoto", url = url, description = description})
end)

RegisterNUICallback('close',function ()
    SetNuiFocus(false,false)
end)


--------------------------------------------
--------------------------------------------
--------------------------------------------
TriggerServerEvent(GetCurrentResourceName()..':server:RequestEvidences')