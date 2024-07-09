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
Config.PoliceShowEvidenceWeapom = `WEAPON_FLASHLIGHT` -- FLASHLIGHT TO SHOW EVIDENCE
Config.PoliceShowEvidenceWeapomAim = true -- NEED TO AIM WEAPON TO SHOW EVIDENCE
Config.PoliceEvidenceMaxDist = 5.0 -- MAX DISTANCE TO SHOW EVIDENCE WHEN USING FLASHLIGHT

-- EVIDENCE
Config.BloodNPC = false -- Allow NPC leat blood evidence
Config.AllowFootprint = false -- Allow Player Footprint evidence
Config.ShowShootersLine = true -- SHOW SHOT LINE
Config.DegradeTime = 5 -- EACH MINUTES THE EVIDENCE DEGRADE 1%
Config.DegradeLevel = {
    lowQuality = 90, -- lowQuality degrade will not be able to connect evidence
    mediumQuality = 50 -- mediumQuality will have 50% change colect evidence
}

-- CAMERA
Config.FiveManageImgToken = 'SJ52pa9Z6e7VpVuNKkZaU5PSfONlcVgO'
Config.cameraProp = `prop_pap_camera_01`
Config.photoItem = 'evidence_photo'
Config.camEvidenceMaxDistance = 20.0