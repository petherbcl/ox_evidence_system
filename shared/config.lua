--[[
    estrutura evidence

    {
        TYPE:
        CDS:
        USER_IDENTIFIER:

        BLOODTYPE:
        WEAPON_TYPE:
        WEAPON_SERIAL:
    }
]]

Config = {}

Config.Framework = 'standalone'

-- THIS WEAPONS DON'T LEAVE EVIDENCE
Config.WhitelistWeapon = {
    `weapon_unarmed`,
    `weapon_snowball`,
    `weapon_stungun`,
    `weapon_petrolcan`,
    `weapon_hazardcan`,
    `weapon_fireextinguisher`
}

-- POLICE JOB
Config.PoliceJob = 'DPCNX' -- JOB PERMISSION
Config.PoliceEvidence = true -- POLICE WILL ALSO LEAVE EVIDENCE

Config.BloodNPC = false -- Allow NPC leat blood evidence