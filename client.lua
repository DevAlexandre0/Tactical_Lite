-- ====================================================================
-- UTILITIES
-- ====================================================================
local GMath = {}

function GMath.GetCameraDirection()
    local rot = GetGameplayCamRot(2)
    local tZ, tX = math.rad(rot.z), math.rad(rot.x)
    local num = math.abs(math.cos(tX))
    return vector3(-math.sin(tZ) * num, math.cos(tZ) * num, math.sin(tX))
end

local function LerpTime(start, target, startTime, duration)
    local elapsed = GetGameTimer() - startTime
    local t = math.min(elapsed / duration, 1.0)
    t = t * t * (3.0 - 2.0 * t) 
    return start + (target - start) * t
end

-- ====================================================================
-- TACTICAL LEAN SYSTEM
-- ====================================================================
local Lean = {}
Lean.cam = nil
Lean.stance = 0
Lean.PeekingPosition = 0
Lean.activeState = { mode = "NONE", crouch = false }
Lean.lastTickTime = 0

-- Variables for Lerp
local startLerpRot, reversLerpRot, sLerpRot = 0.0, 0.0, 0.0
local initialCamCoords, targetLeanCoords, activeLeanCoords = nil, nil, nil
local CamDidHit, GameplayCameraDidHit = false, false

local function GetCameraPositionX()
    local viewMode = GetFollowPedCamViewMode()
    local multiplier = Lean.PeekingPosition == 1 and 1.0 or -1.0
    local extraRight = Lean.PeekingPosition == 1 and Config.Lean.TPV.extraRightOffset or 0
    
    if viewMode == 0 then return (Config.Lean.TPV.lateralOffsetClose + extraRight) * multiplier
    elseif viewMode == 1 then return (Config.Lean.TPV.lateralOffsetMedium + extraRight) * multiplier
    elseif viewMode == 2 then return (Config.Lean.TPV.lateralOffsetFar + extraRight) * multiplier
    end
    return 0.0
end

local function GetCameraPositionTranslation(gameplayCamCoords, pedCoords)
    local x = GetCameraPositionX()
    local z = Config.Lean.TPV.verticalOffset
    local forward = GetEntityForwardVector(PlayerPedId())
    local camToPed = gameplayCamCoords - pedCoords
    local yDist = (forward.x * camToPed.x) + (forward.y * camToPed.y)
    return vector3(x, yDist, z)
end

local function CheckCollision(ped, targetPos)
    local pedPos = GetEntityCoords(ped)
    local raycast = StartShapeTestCapsule(pedPos.x, pedPos.y, pedPos.z, targetPos.x, targetPos.y, targetPos.z, 0.2, 511, ped, 4)
    local _, hit = GetShapeTestResult(raycast)
    return hit == 1
end

local function CleanupCameraImmediate()
    if Lean.cam then
        RenderScriptCams(false, false, 0, true, true)
        SetCamActive(Lean.cam, false)
        DestroyCam(Lean.cam, false)
        Lean.cam = nil
    end
    Lean.stance = 0
    Lean.PeekingPosition = 0
    Lean.initialCamCoords = nil
    Lean.targetLeanCoords = nil
    Lean.activeLeanCoords = nil
end

local function DrawTacticalReticle()
    DrawRect(0.5, 0.5, 0.0030, 0.0030, 255, 255, 255, 200)
end

function Lean.Update(ped, isAiming, qPressed, ePressed)
    local viewMode = GetFollowPedCamViewMode()
    if viewMode == 4 then -- Disable in First Person
        if Lean.stance ~= 0 then CleanupCameraImmediate() end
        return 
    end

    if Lean.stance > 0 then DrawTacticalReticle() end
    local isCrouching = IsPedDucking(ped)
    local targetMode = "NONE"

    if not isAiming then
        if Lean.stance ~= 0 then
            ClearPedSecondaryTask(ped)
            CleanupCameraImmediate()
        end
        return
    end

    -- Input Handling
    if isAiming then
        if ePressed and Lean.stance == 0 then
            local anim = isCrouching and Config.Lean.Anims.RIGHT.low or Config.Lean.Anims.RIGHT.high
            lib.requestAnimDict(anim.dict)
            TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, 49, 0, false, false, false)
            Lean.PeekingPosition, Lean.stance, targetMode = 1, 1, "RIGHT"
        elseif qPressed and Lean.stance == 0 then
            local anim = isCrouching and Config.Lean.Anims.LEFT.low or Config.Lean.Anims.LEFT.high
            lib.requestAnimDict(anim.dict)
            TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, 49, 0, false, false, false)
            Lean.PeekingPosition, Lean.stance, targetMode = 2, 1, "LEFT"
        end

        if Lean.stance >= 1 and Lean.stance <= 3 then
            if (Lean.PeekingPosition == 1 and not ePressed) or (Lean.PeekingPosition == 2 and not qPressed) then
                ClearPedSecondaryTask(ped)
                Lean.stance = 4
            end
        end
        
        if Lean.PeekingPosition == 1 then targetMode = "RIGHT" 
        elseif Lean.PeekingPosition == 2 then targetMode = "LEFT" end
    end

    -- State Sync (OneSync)
    if Lean.activeState.mode ~= targetMode or Lean.activeState.crouch ~= isCrouching then
        Lean.activeState = { mode = targetMode, crouch = isCrouching }
        LocalPlayer.state:set('TacticalLean', Lean.activeState, true)
    end

    -- Camera Logic
    if Lean.stance == 1 then -- STARTING
        local coords = GetGameplayCamCoord()
        local rot = GetGameplayCamRot(2)
        local pedCoords = GetEntityCoords(ped)
        
        initialCamCoords = coords
        local posTrans = GetCameraPositionTranslation(coords, pedCoords)
        targetLeanCoords = GetOffsetFromEntityInWorldCoords(ped, posTrans.x, posTrans.y, posTrans.z)
        
        if not Lean.cam then
            Lean.cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, GetGameplayCamFov(), true, 2)
        end
        SetCamActive(Lean.cam, true)
        RenderScriptCams(true, false, 0, true, true)
        Lean.lastTickTime, Lean.stance = GetGameTimer(), 2

    elseif Lean.stance == 2 then -- LERPING
        local lerpT = LerpTime(0.0, 1.0, Lean.lastTickTime, 333)
        startLerpRot = lerpT * (Lean.PeekingPosition == 1 and 1.0 or -1.0) * Config.Lean.TPV.cameraRoll
        
        local lX = initialCamCoords.x + (targetLeanCoords.x - initialCamCoords.x) * lerpT
        local lY = initialCamCoords.y + (targetLeanCoords.y - initialCamCoords.y) * lerpT
        local lZ = initialCamCoords.z + (targetLeanCoords.z - initialCamCoords.z) * lerpT
        
        activeLeanCoords = vector3(lX, lY, lZ)
        SetCamCoord(Lean.cam, lX, lY, lZ)
        SetCamRot(Lean.cam, GetGameplayCamRot(2).x, GetGameplayCamRot(2).y + startLerpRot, GetGameplayCamRot(2).z, 2)
        SetCamFov(Lean.cam, GetGameplayCamFov())
        
        if lerpT >= 0.99 then Lean.lastTickTime, Lean.stance = GetGameTimer(), 3 end

    elseif Lean.stance == 3 then -- ACTIVE
        if Lean.PeekingPosition ~= 0 then
            local gameRot = GetGameplayCamRot(2)
            local gameCamCoord = GetGameplayCamCoord()
            local pedCoords = GetEntityCoords(ped)
            
            local posTrans = (not CamDidHit or not GameplayCameraDidHit) and GetCameraPositionTranslation(gameCamCoord, pedCoords) or vector3(0,0,0)
            local offsetPos = GetOffsetFromEntityInWorldCoords(ped, posTrans.x, posTrans.y, posTrans.z)
            
            activeLeanCoords = offsetPos
            SetCamCoord(Lean.cam, offsetPos.x, offsetPos.y, offsetPos.z)
            local roll = (Lean.PeekingPosition == 1 and 1.0 or -1.0) * Config.Lean.TPV.cameraRoll
            SetCamRot(Lean.cam, gameRot.x, gameRot.y + roll, gameRot.z, 2)
            SetCamFov(Lean.cam, GetGameplayCamFov())
            
            CamDidHit = CheckCollision(ped, offsetPos)
            GameplayCameraDidHit = CheckCollision(ped, GetOffsetFromEntityInWorldCoords(ped, GetCameraPositionX(), 0, 0))
        end

    elseif Lean.stance == 4 then -- ENDING
        sLerpRot = (Lean.PeekingPosition == 1 and 1.0 or -1.0) * Config.Lean.TPV.cameraRoll
        Lean.lastTickTime, Lean.stance = GetGameTimer(), 5

    elseif Lean.stance == 5 then -- REVERSING
        local lerpT = LerpTime(0.0, 1.0, Lean.lastTickTime, 333)
        reversLerpRot = sLerpRot * (1.0 - lerpT)
        local gameplayCam = GetGameplayCamCoord()
        
        local lX = activeLeanCoords.x + (gameplayCam.x - activeLeanCoords.x) * lerpT
        local lY = activeLeanCoords.y + (gameplayCam.y - activeLeanCoords.y) * lerpT
        local lZ = activeLeanCoords.z + (gameplayCam.z - activeLeanCoords.z) * lerpT
        
        SetCamCoord(Lean.cam, lX, lY, lZ)
        SetCamRot(Lean.cam, GetGameplayCamRot(2).x, GetGameplayCamRot(2).y + reversLerpRot, GetGameplayCamRot(2).z, 2)
        SetCamFov(Lean.cam, GetGameplayCamFov())
        
        if lerpT >= 0.99 then Lean.stance = 6 end

    elseif Lean.stance == 6 then -- CLEANUP
        CleanupCameraImmediate()
    end
end

-- Sync Handler for other players
AddStateBagChangeHandler('TacticalLean', nil, function(bagName, key, value, _unused, replicated)
    local ply = GetPlayerFromStateBagName(bagName)
    if not ply or ply == PlayerId() then return end
    local remotePed = GetPlayerPed(ply)
    if not DoesEntityExist(remotePed) then return end
    
    if not value or value.mode == "NONE" then
        ClearPedSecondaryTask(remotePed)
    else
        local animData = value.crouch and Config.Lean.Anims[value.mode].low or Config.Lean.Anims[value.mode].high
        lib.requestAnimDict(animData.dict)
        TaskPlayAnim(remotePed, animData.dict, animData.clip, 8.0, -8.0, -1, 49, 0, false, false, false)
    end
end)

-- ====================================================================
-- QUICK THROW SYSTEM
-- ====================================================================
local Grenade = {}
Grenade.lastThrowTime = 0
Grenade.isThrowing = false
local R_HAND_BONE = 28422
local ANIM_DICT = "weapons@projectile@aim_throw_rifle"
local ANIM_NAME = "aim_throw_m"

local function GetBestThrowable()
    for _, cfg in ipairs(Config.QuickThrow.Throwables) do
        local count = exports.ox_inventory:Search('count', cfg.item)
        if count > 0 then return cfg end
    end
    return nil
end

local function FireNetworkedProjectile(ped, hash, speed)
    local camDir = GMath.GetCameraDirection()
    local spawnPos = GetPedBoneCoords(ped, R_HAND_BONE, 0.0, 0.0, 0.0)
    local finalSpawn = spawnPos + (camDir * 0.8)
    local finalTarget = finalSpawn + (camDir * 50.0)
    
    ShootSingleBulletBetweenCoords(
        finalSpawn.x, finalSpawn.y, finalSpawn.z,
        finalTarget.x, finalTarget.y, finalTarget.z,
        0, true, hash, ped, true, false, speed
    )
end

local function ProcessQuickThrow()
    local ped = PlayerPedId()
    if Grenade.isThrowing or not Config.QuickThrow.Enabled then return end
    if not IsPlayerFreeAiming(PlayerId()) or IsPedInAnyVehicle(ped, false) then return end

    local throwable = GetBestThrowable()
    if not throwable then
        return lib.notify({ type = 'error', description = 'ไม่มีอาวุธขว้างในตัว!' })
    end

    local now = GetGameTimer()
    if now - Grenade.lastThrowTime < Config.QuickThrow.Cooldown then return end

    Grenade.isThrowing = true
    Grenade.lastThrowTime = now

    CreateThread(function()
        RequestAnimDict(ANIM_DICT)
        RequestWeaponAsset(throwable.hash)
        while not (HasAnimDictLoaded(ANIM_DICT) and HasWeaponAssetLoaded(throwable.hash)) do Wait(10) end

        TaskPlayAnim(ped, ANIM_DICT, ANIM_NAME, 2.0, -2.0, -1, 48, 0, false, false, false)
        Wait(400) -- Wait for throw point

        FireNetworkedProjectile(ped, throwable.hash, throwable.speed)
        TriggerServerEvent('tactical_lite:throwItem', throwable.item)

        Wait(200)
        StopAnimTask(ped, ANIM_DICT, ANIM_NAME, 1.0)
        Grenade.isThrowing = false
        RemoveAnimDict(ANIM_DICT)
    end)
end

RegisterCommand('quick_throw', ProcessQuickThrow, false)
RegisterKeyMapping('quick_throw', 'Quick Tactical Throw', 'keyboard', Config.QuickThrow.Key)

-- ====================================================================
-- MAIN LOOP
-- ====================================================================
local isLeanLeftPressed, isLeanRightPressed = false, false

RegisterCommand('+lean_left', function() isLeanLeftPressed = true end, false)
RegisterCommand('-lean_left', function() isLeanLeftPressed = false end, false)
RegisterCommand('+lean_right', function() isLeanRightPressed = true end, false)
RegisterCommand('-lean_right', function() isLeanRightPressed = false end, false)
RegisterKeyMapping('+lean_left', 'Tactical Lean Left', 'keyboard', 'Q')
RegisterKeyMapping('+lean_right', 'Tactical Lean Right', 'keyboard', 'E')

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local isAiming = IsPlayerFreeAiming(PlayerId()) or IsControlPressed(0, 25)
        
        if isAiming then
            Lean.Update(ped, true, isLeanLeftPressed, isLeanRightPressed)
            Wait(0)
        else
            if Lean.stance ~= 0 then
                Lean.Update(ped, false, false, false)
            end
            Wait(200)
        end
    end
end)