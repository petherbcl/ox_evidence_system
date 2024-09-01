Config = {}

Config.Framework = 'standalone'
Config.Lang = 'pt-br'

-- THIS WEAPONS DON'T LEAVE EVIDENCE
Config.WhitelistWeapon = {
    `weapon_unarmed`,
    `weapon_snowball`,
    `weapon_stungun`,
    `weapon_petrolcan`,
    `weapon_hazardcan`,
    `weapon_fireextinguisher`
}
Config.armsWithoutGloves = {
    male = {
        [0] = true,
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true,
        [6] = true,
        [7] = true,
        [8] = true,
        [9] = true,
        [10] = true,
        [11] = true,
        [12] = true,
        [13] = true,
        [14] = true,
        [15] = true,
        [18] = true,
        [26] = true,
        [52] = true,
        [53] = true,
        [54] = true,
        [55] = true,
        [56] = true,
        [57] = true,
        [58] = true,
        [59] = true,
        [60] = true,
        [61] = true,
        [62] = true,
        [112] = true,
        [113] = true,
        [114] = true,
        [118] = true,
        [125] = true,
        [132] = true,
        [184] = true,
        [188] = true,
        [196] = true,
        [198] = true,
        [202] = true
    },
    female = {
        [0] = true,
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true,
        [6] = true,
        [7] = true,
        [8] = true,
        [9] = true,
        [10] = true,
        [11] = true,
        [12] = true,
        [13] = true,
        [14] = true,
        [15] = true,
        [19] = true,
        [59] = true,
        [60] = true,
        [61] = true,
        [62] = true,
        [63] = true,
        [64] = true,
        [65] = true,
        [66] = true,
        [67] = true,
        [68] = true,
        [69] = true,
        [70] = true,
        [71] = true,
        [129] = true,
        [130] = true,
        [131] = true,
        [135] = true,
        [142] = true,
        [149] = true,
        [153] = true,
        [157] = true,
        [161] = true,
        [183] = true,
        [201] = true,
        [204] = true,
        [229] = true,
        [233] = true,
        [241] = true,
    },
}

-- POLICE JOB
Config.PoliceJob = 'DPCNX' -- JOB PERMISSION
Config.PoliceEvidence = true -- POLICE WILL ALSO LEAVE EVIDENCE
Config.PoliceShowEvidenceWeapom = `WEAPON_FLASHLIGHT` -- FLASHLIGHT TO SHOW EVIDENCE
Config.PoliceShowEvidenceWeapomAim = true -- NEED TO AIM WEAPON TO SHOW EVIDENCE
Config.PoliceEvidenceMaxDist = 5.0 -- MAX DISTANCE TO SHOW EVIDENCE WHEN USING FLASHLIGHT

-- EVIDENCE
Config.InteractKey = 'E' -- KEY TO INTERACT WITH A EVIDENCE
Config.BloodNPC = false -- Allow NPC leat blood evidence
Config.AllowFootprint = false -- Allow Player Footprint evidence
Config.ShowShootersLine = true -- SHOW SHOT LINE
Config.DegradeTime = 28.8 -- EACH MINUTES THE EVIDENCE DEGRADE 1%
Config.DegradeLevel = {
    lowQuality = 90, -- lowQuality will display red color on progress bar (10% change to get evidence)
    mediumQuality = 50 -- mediumQuality will display orange color on progress bar (50% change to get evidence)
}
Config.FingerprintQuality = {
    lowQuality = 5,  -- lowQuality will have 10% change colect evidence ( ex: weapaon has 5 or more fingerprints)
    mediumQuality = 3 -- mediumQuality will have 50% change colect evidence
}

Config.EvidenceCollect = {
    casing = {itemNeed = 'evidence_casing_bag', itemReceive = 'evidence_casing'},
    bullethole = {itemNeed = 'evidence_casing_bag', itemReceive = 'evidence_bullet'},
    vehicleFragment = {itemNeed = 'evidence_casing_bag', itemReceive = 'evidence_vehfagment'},
    blood = {itemNeed = 'evidence_swab_stick', itemReceive = 'evidence_bood'},
    footprint = {itemNeed = 'evidence_fingerprint_kit', itemReceive = 'evidence_footprint'},
    fingerprint = {itemNeed = 'evidence_fingerprint_kit', itemReceive = 'evidence_fingerprint'}
}

Config.AnimCollect = {
    casing = {dict = 'amb@medic@standing@tendtodead@idle_a', clip = 'idle_a'},
    bullethole = {dict = 'amb@medic@standing@tendtodead@idle_a', clip = 'idle_a'},
    vehicleFragment = {dict = 'amb@medic@standing@tendtodead@idle_a', clip = 'idle_a'},
    blood = {dict = 'amb@medic@standing@tendtodead@idle_a', clip = 'idle_a'},
    footprint = {dict = 'amb@medic@standing@tendtodead@idle_a', clip = 'idle_a'},
    fingerprint = {dict = 'amb@prop_human_parking_meter@female@idle_a', clip = 'idle_a_female'},
}

-- CAMERA
Config.FiveManageImgToken = 'SJ52pa9Z6e7VpVuNKkZaU5PSfONlcVgO'
Config.cameraProp = `prop_pap_camera_01`
Config.photoItem = 'evidence_photo'
Config.camEvidenceMaxDistance = 20.0