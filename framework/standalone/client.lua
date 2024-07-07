if Config.Framework~= 'standalone' then return end

PlayerData = {
    characterName = "",
    identifier = '-1',
    job = {
        payment = 1,
        onduty = true,
        grade = {
            level = 0,
            name = "Freelancer"
        },
        name = "unemployed",
        isboss = false,
        type = "none",
        label = "Civilian"
    }
}

RegisterNetEvent(GetCurrentResourceName()..":client:RequestPlayerIdent", function(playerData)
    PlayerData = playerData
end)
TriggerServerEvent(GetCurrentResourceName()..":server:RequestPlayerIdent")

function GetJobInfo()
    return PlayerData.job
end
