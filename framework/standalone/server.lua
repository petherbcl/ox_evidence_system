if Config.Framework~= 'standalone' then return end

--------------------------------------------
-- VARIABLES
--------------------------------------------

local Proxy = module("vrp","lib/Proxy")
local vRP = Proxy.getInterface("vRP")

local JobPermisions = {
    ["DPCNX"] = {
        name = "Dep. Pol. Conexões",
        grades = {
            [13] = {group="AltoComando", name="Alto Comando"},
            [12] = {group="Major", name="Major"},
            [11] = {group="Capitao", name="Capitão"},
            [10]  = {group="1Tenente", name="1º Tenente"},
            [9]  = {group="2Tenente", name="2º Tenente"},
            [8]  = {group="SubTenente", name="SubT enente"},
            [7]  = {group="1Sargento", name="1º Sargento"},
            [6]  = {group="2Sargento", name="2º Sargento"},
            [5]  = {group="3Sargento", name="3º Sargento"},
            [4]  = {group="Cabo", name="Cabo"},
            [3]  = {group="1Soldado", name="1º Soldado"},
            [2]  = {group="2Soldado", name="2º Soldado"},
            [1]  = {group="Recruta", name="Recruta"},
        }
    }
}

--------------------------------------------
-- LOCAL FUNCTIONS
--------------------------------------------

local function getUserJobs(source, user_id)
    if not user_id then
        user_id = vRP.getUserId(source)
    end

    local jobdata = {
        name = "unemployed",
        label = "Cidadão",
        type = "none",
        onduty = true,
        isboss = false,
        grade = {
            level = 1,
            name = "Desempregado"
        },
    }

    for job, job_value in pairs(JobPermisions) do
        if vRP.hasPermission(user_id, job) then
            jobdata.name = job
            jobdata.label = job_value.name
            jobdata.onduty = true
            for grade_index, grade_info in pairs(job_value.grades) do
                if vRP.hasPermission(user_id, grade_info.group) then
                    jobdata.grade.level = tonumber(grade_index)
                    jobdata.grade.name = grade_info.name
                    jobdata.isboss = grade_index==#job_value.grades and true or false
                    break
                end
            end
            break
        end
    end

    return jobdata
end

local function GetCharacterName(source, user_id)
    if not user_id then
        user_id = vRP.getUserId(source)
    end
    local identity = vRP.userIdentity(user_id)
    local name = ''
    if identity then
        name = identity.name.." "..identity.name2
    end
    return name
end

local function updatePlayerData(source, user_id)
    local PlayerData = {
        identifier = tostring(user_id),
        characterName = GetCharacterName(source, user_id),
        job = getUserJobs(source, user_id),
    }
    TriggerClientEvent(GetCurrentResourceName()..":standalone:client:RequestPlayerIdent",source, PlayerData)
end

--------------------------------------------
-- FUNCTIONS
--------------------------------------------
RegisterNetEvent(GetCurrentResourceName()..':standalone:server:RequestPlayerIdent', function()
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        updatePlayerData(source, user_id)
    end
end)

function getPlayerIdentifier(source)
    return vRP.getUserId(source)
end

function getPlayerName(source)
    local user_id = vRP.getUserId(source)
    local identity = vRP.userIdentity(user_id)
    local name = ''
    if identity then
        name = identity.name.." "..identity.name2
    end
    return name
end

lib.callback.register(GetCurrentResourceName()..':standalone:server:GetPlayerBloodType', function(source, playerSource)
    local user_id = vRP.getUserId(playerSource)
    if user_id then
        local identity = vRP.userIdentity(user_id)
        return identity.blood
    end
    return nil
end)

function HasItems(source, item, amount)
    return exports.ox_inventory:GetItemCount(source, item)>(amount or 0)
end

function GiveItem(source, item, amount, metadata)
    vRP.giveInventoryItem(vRP.getUserId(source),item,amount,nil,nil,metadata)
end

function RemoveItem(source, item, amount)
    vRP.tryGetInventoryItem(vRP.getUserId(source),item,amount)
end
--------------------------------------------
-- EVENTS
--------------------------------------------

AddEventHandler("playerConnect",function(user_id,source)
    updatePlayerData(source, user_id)
end)

RegisterNetEvent('vRP:updatePerm', function(source,user_id)
    updatePlayerData(source, user_id)
end)
