XModelManager = XModelManager or {}

local Ui_MODEL_TRANSFORM_PATH = "Client/Ui/UiModelTransform.tab"
local Ui_SCENE_TRANSFORM_PATH = "Client/Ui/UiSceneTransform.tab"
local MODEL_TABLE_PATH = "Client/ResourceLut/Model/Model.tab"
local UIMODEL_TABLE_PATH = "Client/ResourceLut/Model/UIModel.tab"
local XEquipModel = require("XEntity/XEquip/XEquipModel")

XModelManager.MODEL_ROTATION_VALUE = 10

XModelManager.MODEL_UINAME = {
    XUiMain = "UiMain",
    XUiCharacter = "UiCharacter",
    XUiPanelCharLevel = "UiPanelCharLevel",
    XUiPanelCharQuality = "UiPanelCharQuality",
    XUiPanelCharSkill = "UiPanelCharSkill",
    XUiPanelCharGrade = "UiPanelCharGrade",
    XUiPanelSelectLevelItems = "UiPanelSelectLevelItems",
    XUiPreFight = "UiPreFight",
    XUiDisplay = "UiDisplay",
    XUiFashion = "UiFashion",
    XUiFashionDetail = "UiFashionDetail",
    XUiNewPlayerTask = "UiNewPlayerTask",
    XUiBossSingle = "UiPanelBossDetail",
    XUiOnlineBoss = "UiOnlineBoss",
    XUiDormCharacterDetail = "UiDormCharacterDetail",
    XUiFurnitureDetail = "UiDormFurnitureDetail",
    XUiFavorabilityLineRoomCharacter = "UiFavorabilityLineRoomCharacter",
    XUiDrawShow = "UiDrawShow",
    XUiBabelTowerRoomCharacter = "UiBabelTowerRoomCharacter",
    UiArchiveMonsterDetail = "UiArchiveMonsterDetail",
    XUiRogueLikeRoomCharacter = "UiRogueLikeRoomCharacter",
    XUiUnionKillSelectRole = "UiUnionKillXuanRen",
    XUiUnionKillRank = "UiUnionKillRank",
    XUiGuildMain = "UiGuildMain",
    XUiWorldBossBossArea = "UiWorldBossBossArea",
    XUiExhibitionInfo = "UiExhibitionInfo",
    XUiPhotograph = "UiPhotograph",
    XUiActivityBriefBase = "XUiActivityBriefBase",
    XUiTRPGYingDi = "XUiTRPGYingDi",
    XUiTRPGWorldBossBossArea = "UiTRPGWorldBossBossArea",
    XUiNieRPOD = "XUiNieRPOD",
    XUiPokemonMonster = "UiPokemonMonster",
    XUiLottoShow = "UiLottoShow",
    XUiPartnerMain = "UiPartnerMain",
    XUiMoeWarMessage = "UiMoeWarMessage",
    XUiMoeWarSchedule = "UiMoeWarSchedule",
    XUiMoeWarVote = "UiMoeWarVote",
    UiReform = "UiReform",
}

--local RoleModelPool = {} --????????????
local UiModelTransformTemplates = {} -- Ui?????????????????????
local UiSceneTransformTemplates = {} -- Ui?????????????????????
local ModelTemplates = {} -- ??????????????????
local UIModelTemplates = {} -- UI??????????????????
local LuaBehaviourDict = {} -- ????????????????????????

--??????Model?????????
function XModelManager.Init()
    ModelTemplates = XTableManager.ReadByStringKey(MODEL_TABLE_PATH, XTable.XTableModel, "Id")
    UIModelTemplates = XTableManager.ReadByStringKey(UIMODEL_TABLE_PATH, XTable.XTableUiModel, "Id")

    UiModelTransformTemplates = {}
    UiSceneTransformTemplates = {}

    local tab = XTableManager.ReadByIntKey(Ui_MODEL_TRANSFORM_PATH, XTable.XTableUiModelTransform, "Id")
    for _, config in pairs(tab) do
        if not UiModelTransformTemplates[config.UiName] then
            UiModelTransformTemplates[config.UiName] = {}
        end
        UiModelTransformTemplates[config.UiName][config.ModelName] = config
    end

    local sceneTab = XTableManager.ReadByIntKey(Ui_SCENE_TRANSFORM_PATH, XTable.XTableUiSceneTransform, "Id")
    for _, config in pairs(sceneTab) do
        if not UiSceneTransformTemplates[config.UiName] then
            UiSceneTransformTemplates[config.UiName] = {}
        end
        UiSceneTransformTemplates[config.UiName][config.SceneUrl] = config
    end
end

local function GetUiModelConfig(modelId)
    local config = UIModelTemplates[modelId]--UI????????????
    or ModelTemplates[modelId]--????????????????????????????????????
    if not config then
        XLog.Error("XModelManager GetUiModelConfig error: ?????????????????????, modelId: " .. modelId .. " ,????????????: " .. UIMODEL_TABLE_PATH)
        return
    end
    return config
end

local function GetModelConfig(modelId)
    local config = ModelTemplates[modelId]--??????????????????
    if not config then
        XLog.Error("XModelManager GetModelConfig error: ?????????????????????, modelId: " .. modelId .. " ,????????????: " .. MODEL_TABLE_PATH)
        return
    end
    return config
end

------UI?????? begin --------
function XModelManager.GetUiModelPath(modelId)
    local config = GetUiModelConfig(modelId)
    return config.ModelPath
end

function XModelManager.GetUiDisplayControllerPath(modelId)
    local config = GetUiModelConfig(modelId)
    return config.DisplayControllerPath
end

function XModelManager.GetUiDefaultAnimationPath(modelId)
    local config = GetUiModelConfig(modelId)
    return config.UiDefaultAnimationPath
end

function XModelManager.GetUiControllerPath(modelId)
    local config = GetUiModelConfig(modelId)
    return config.ControllerPath
end

--?????????????????????????????????????????????
function XModelManager.GetUiFashionControllerPath(modelId)
    local config = GetUiModelConfig(modelId)
    return config.FashionControllerPath
end
------UI?????? end --------
------??????C#?????? begin --------
function XModelManager.GetModelPath(modelId)
    local config = GetModelConfig(modelId)
    return config.ModelPath
end

function XModelManager.GetLowModelPath(modelId)
    local config = GetModelConfig(modelId)
    return config.LowModelPath
end

function XModelManager.GetControllerPath(modelId)
    local config = GetModelConfig(modelId)
    return config.ControllerPath
end
------??????C#?????? end --------
function XModelManager.GetRoleModelConfig(uiName, modelName)
    if not uiName or not modelName then
        XLog.Error("XModelManager.GetRoleMoadelConfig ????????????: ??????uiName???modelName???????????????")
        return
    end

    if UiModelTransformTemplates[uiName] then
        return UiModelTransformTemplates[uiName][modelName]
    end
end

function XModelManager.GetSceneModelConfig(uiName, sceneUrl)
    if not uiName or not sceneUrl then
        XLog.Error("XModelManager.GetSceneModelConfig ????????????: ??????uiName???sceneUrl???????????????")
        return
    end

    if UiSceneTransformTemplates[uiName] then
        return UiSceneTransformTemplates[uiName][sceneUrl]
    end
end

function XModelManager.LoadSceneModel(sceneUrl, parent, uiName)
    local scene = CS.LoadHelper.InstantiateScene(sceneUrl)
    scene.transform:SetParent(parent, false)
    if uiName then
        XModelManager.SetSceneTransform(sceneUrl, scene, uiName)
    end
    return scene
end

--???UI??????
function XModelManager.LoadRoleModel(modelId, target, refName, cb)
    if not modelId or not target then
        return
    end

    local modelPath = XModelManager.GetUiModelPath(modelId)
    local model = CS.LoadHelper.InstantiateNpc(modelPath, refName)
    model.transform:SetParent(target, false)
    model.gameObject:SetLayerRecursively(target.gameObject.layer)
    model.transform.localScale = CS.UnityEngine.Vector3.one
    model.transform.localPosition = CS.UnityEngine.Vector3.zero
    model.transform.localRotation = CS.UnityEngine.Quaternion.identity

    if cb then
        cb(model)
    end
end

local setModeTransform = function(target, config)
    if not target or not config then
        return
    end

    target.transform.localPosition = CS.UnityEngine.Vector3(config.PositionX, config.PositionY, config.PositionZ)
    --???????????? ????????????
    target.transform.localEulerAngles = CS.UnityEngine.Vector3(config.RotationX, config.RotationY, config.RotationZ)
    --???????????? ????????????
    target.transform.localScale = CS.UnityEngine.Vector3(
    config.ScaleX == 0 and 1 or config.ScaleX,
    config.ScaleY == 0 and 1 or config.ScaleY,
    config.ScaleZ == 0 and 1 or config.ScaleZ
    )
end

function XModelManager.SetSceneTransform(sceneUrl, target, uiName)
    target.transform.localPosition = CS.UnityEngine.Vector3.zero
    target.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
    target.transform.localScale = CS.UnityEngine.Vector3.one

    if not uiName then
        return
    end

    local config = XModelManager.GetSceneModelConfig(uiName, sceneUrl)
    if not config then
        return
    end

    setModeTransform(target, config)

end

function XModelManager.SetRoleTransform(name, target, uiName)
    target.transform.localPosition = CS.UnityEngine.Vector3.zero
    target.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
    target.transform.localScale = CS.UnityEngine.Vector3.one

    if not uiName then
        return
    end

    local config = XModelManager.GetRoleModelConfig(uiName, name)
    if not config then
        return
    end

    setModeTransform(target, config)
end

function XModelManager.CheckAnimatorAction(animator, actionName)
    if not actionName then
        return false
    end
    if not (animator and animator:Exist() and animator.runtimeAnimatorController and animator.gameObject.activeInHierarchy) then
        return false
    end

    local animationClips = animator.runtimeAnimatorController.animationClips
    for i = 0, animationClips.Length - 1 do
        local tempClip = animationClips[i]
        if tempClip:Exist() and tempClip.name == actionName then
            return true
        end
    end
    XLog.Warning(animator.runtimeAnimatorController.name .. "  ???????????????ID???" .. actionName)
    return false
end

---=================================================
--- ???????????????????????????????????????????????????
---@overload fun(callBack:function)
---@param callBack function
---=================================================
local CheckAnimeFinish = function(animator, behaviour, animaName, callBack)--???????????????????????????????????????????????????
    local animatorInfo = animator:GetCurrentAnimatorStateInfo(0)
    if (animatorInfo:IsName(animaName) and animatorInfo.normalizedTime >= 1) or not animatorInfo:IsName(animaName) then--normalizedTime?????????0~1???0????????????1????????????
        if callBack then callBack() end
        behaviour.enabled = false
    end
end

local AddPlayingAnimCallBack = function(obj, animator, animaName, callBack)
    local animatorInfo = animator:GetCurrentAnimatorStateInfo(0)

    if not animatorInfo:IsName(animaName) or animatorInfo.normalizedTime >= 1 then--normalizedTime?????????0~1???0????????????1????????????
        return
    end

    local behaviour = obj.transform:GetComponent(typeof(CS.XLuaBehaviour))
    if not behaviour then
        behaviour = obj.gameObject:AddComponent(typeof(CS.XLuaBehaviour))
    else
        behaviour.enabled = true
    end

    behaviour.LuaUpdate = function()
        CheckAnimeFinish(animator, behaviour, animaName, callBack)
    end
end

---=================================================
--- ??????'AnimaName'????????????fromBegin???????????????????????????????????????0???????????????????????????false
---@overload fun(AnimaName:string)
---@param obj ????????????
---@param animator Animator??????
---@param animaName string
---@param fromBegin boolean
---@param callBack function ??????????????????
---@param finishCallBack function ???????????????????????????????????????
---@param errorCb function ?????????????????????
---=================================================
function XModelManager.PlayAnima(obj, animator, animaName, fromBegin, callBack, errorCb, finishCallBack)
    local isCanPlay = XModelManager.CheckAnimatorAction(animator, animaName)
    if isCanPlay and animator then
        if fromBegin then
            animator:Play(animaName, 0, 0)
        else
            animator:Play(animaName)
        end
        if finishCallBack then
            XScheduleManager.ScheduleOnce(function()
                AddPlayingAnimCallBack(obj, animator, animaName, finishCallBack)
            end, 1)
        end
        if callBack then
            XScheduleManager.ScheduleOnce(function()
                callBack()
            end, 1)
        end
    else
        if errorCb then
            errorCb()
        end
    end
end

--==============================--
--@param: ????????????id??????
--      showEffect ????????????
--      gameObject ????????????????????????
--      noShowing  ???????????????????????????????????????????????????????????????
--      noRotation ???????????????
--      usage      ????????????(XEquipConfig.WeaponUsage)
--      noSound    ???????????????
function XModelManager.LoadWeaponModel(modelId, target, transformConfig, uiName, cb, param)
    if not modelId or XTool.UObjIsNil(target) then
        return
    end

    if type(transformConfig) == "function" then
        cb = transformConfig
        transformConfig = nil
    end

    local XEquipConfig = XEquipConfig
    local usage = param and param.usage or XEquipConfig.WeaponUsage.Show
    local name = XEquipConfig.GetEquipModelName(modelId, usage)

    local model = target:LoadPrefab(name, false)
    if transformConfig then
        setModeTransform(model, transformConfig)
    end

    if not param or not param.showEffect then  -- ??????????????????
        local effectPath = XEquipConfig.GetEquipModelEffectPath(modelId, usage)
        XModelManager.LoadWeaponEffect(model, effectPath)
    end

    local gameObject = param and param.gameObject
    XModelManager.PlayWeaponShowing(model, modelId, uiName, gameObject, param)

    -- ????????????
    if gameObject and not (param and param.noRotation) then
        XModelManager.AutoRotateWeapon(target, model, modelId, gameObject)
    end

    if cb then
        cb(model)
    end
end

function XModelManager.AutoRotateWeapon(target, model, modelId, go)
    local equipModelObj = XModelManager.GetOrCreateLuaBehaviour(go)
    equipModelObj:AutoRotateWeapon(target, model, modelId)
end

-- ???????????????????????????
--  param????????? XModelManager.LoadWeaponModel
function XModelManager.PlayWeaponShowing(target, modelId, uiName, go, param)

    local usage = param and param.usage or XEquipConfig.WeaponUsage.Show
    local noShowing = param and param.noShowing
    local noSound = param and param.noSound
    local roleModelId = param and param.roleModelId
    local notCareNoAnim = false

    local animController = XEquipConfig.GetEquipAnimController(modelId, usage)
    local animator

    if animController and uiName then
        animator = target:GetComponent("Animator")
        animator.runtimeAnimatorController = CS.LoadHelper.LoadUiController(animController, uiName)

        if animator.runtimeAnimatorController and roleModelId then
            local params = XEquipConfig.GetEquipAnimParams(roleModelId)
            if params ~= 0 then
                animator:SetInteger("UiAnime", params)
                notCareNoAnim = true
            end

        end

        -- ???????????????????????? ???????????????
        local equipModelObj = XModelManager.GetLuaBehaviour(go)
        if equipModelObj then
            equipModelObj:ClearAudioInfo()
        end
    end

    --??????????????????????????????????????????
    if notCareNoAnim then
    else
        if noShowing then
            return
        end
    end

    local playSound = true
    -- ??????????????????????????? - ?????? - ????????????????????????
    local animStateName = XEquipConfig.GetEquipUiAnimStateName(modelId, usage)
    if animStateName then
        animator = animator or target:GetComponent("Animator")
        if animator and XModelManager.CheckAnimatorAction(animator, animStateName) then
            -- ??????
            animator:Play(animStateName)
            -- ??????
            local hasUiParam = false
            local parameters = animator.parameters
            for i = 0, parameters.Length - 1 do
                if parameters[i].name == "UiActionBegin" then
                    hasUiParam = true
                    break
                end
            end
            if hasUiParam then
                local animDelay = XEquipConfig.GetEquipUiAnimDelay(modelId, usage)
                if animDelay and animDelay > 0 then
                    playSound = false
                    XScheduleManager.ScheduleOnce(function()
                        if not XTool.UObjIsNil(animator) then
                            animator:SetBool("UiActionBegin", true)
                            if not noSound then
                                XModelManager.PlayWeaponSound(modelId, go, usage)
                            end
                        end
                    end, animDelay)
                else
                    animator:SetBool("UiActionBegin", true)
                end
            end
        else
            playSound = false
        end
    end
    if playSound then
        if not noSound then
            XModelManager.PlayWeaponSound(modelId, go, usage)
        end
    end
end

function XModelManager.PlayWeaponSound(modelId, go, usage)
    if not go then -- ????????????gameObject??????????????????
        return
    end

    local animCueId = XEquipConfig.GetEquipUiAnimCueId(modelId, usage)
    if animCueId and animCueId ~= 0 then
        local audioInfo = CS.XAudioManager.PlaySound(animCueId) -- ??????
        XModelManager.AddAudioInfo(go, audioInfo)
    end
end

-- ???????????????????????????gameObject????????????
function XModelManager.AddAudioInfo(go, audioInfo)
    local equipModelObj = XModelManager.GetOrCreateLuaBehaviour(go)
    equipModelObj:AddAudioInfo(audioInfo)
end

-- ??????????????????
function XModelManager.LoadWeaponEffect(model, effectPath)
    if not effectPath then return end
    if XTool.UObjIsNil(model) then return end

    local target = model.transform:FindTransform("WeaponCenter")
    if XTool.UObjIsNil(target) then return end

    target:LoadPrefab(effectPath, false)
end

--==============================--
--desc: ??????????????????
--@roleModel: ????????????
--@equipModelIdList: ????????????id??????
--==============================--
function XModelManager.LoadRoleWeaponModel(roleModel, equipModelIdList, refName, cb, hideEffect, go, roleModelId)
    if not roleModel then
        return
    end

    local isShowing = (XDataCenter.SetManager.WeaponTransType == XSetConfigs.WeaponTransEnum.Open)

    local usage = XEquipConfig.WeaponUsage.Role
    for i = 1, #equipModelIdList do
        local modelId = equipModelIdList[i]
        if modelId then
            local weaponCase = roleModel.transform.FindTransform(roleModel.transform, "WeaponCase" .. i)
            if not weaponCase then
                XLog.Warning("XModelManager.LoadRoleWeaponModel warning, " .. "WeaponCase" .. i .. " not found")
            else
                XModelManager.LoadWeaponModel(modelId, weaponCase, nil, refName, cb, { showEffect = not hideEffect, noShowing = not isShowing, noRotation = true, usage = usage, gameObject = go, noSound = true, roleModelId = roleModelId })
            end
        end
    end

    -- ???????????????????????????????????????CallBack
    if #equipModelIdList <= 0 and cb then
        cb()
    end
end

-- ??????FightNpcData??????????????????????????????
function XModelManager.LoadRoleWeaponModelByFight(roleModel, fightNpcData, refName, go, roleModelId)
    if not roleModel then
        return
    end

    local isShowing = (XDataCenter.SetManager.WeaponTransType == XSetConfigs.WeaponTransEnum.Open)

    local usage = XEquipConfig.WeaponUsage.Role
    local idList = XDataCenter.EquipManager.GetEquipModelIdListByFight(fightNpcData)
    for i, modelId in ipairs(idList) do
        local weaponCase = roleModel.transform.FindTransform(roleModel.transform, "WeaponCase" .. i)
        if not weaponCase then
            XLog.Warning("XModelManager.LoadRoleWeaponModel warning, " .. "WeaponCase" .. i .. " not found")
        else
            XModelManager.LoadWeaponModel(modelId, weaponCase, nil, refName, nil, { noShowing = not isShowing, noRotation = true, usage = usage, gameObject = go, noSound = true, roleModelId = roleModelId })
        end
    end
end

--==============================
--desc:  ???????????????XLuaBehaviour???????????????????????????
--==============================
function XModelManager.GetLuaBehaviour(go)
    if XTool.UObjIsNil(go) then
        return nil
    end
    return LuaBehaviourDict[go]
end

function XModelManager.GetOrCreateLuaBehaviour(go)
    if not LuaBehaviourDict[go] then
        local behaviour = go:GetComponent(typeof(CS.XLuaBehaviour))
        if not behaviour then
            behaviour = go:AddComponent(typeof(CS.XLuaBehaviour))
        end
        local obj = XEquipModel.New(go, behaviour)
        LuaBehaviourDict[go] = obj
    end
    return LuaBehaviourDict[go]
end

function XModelManager.RemoveLuaBehaviour(go)
    LuaBehaviourDict[go] = nil
end