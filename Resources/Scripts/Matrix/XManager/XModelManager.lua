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

--local RoleModelPool = {} --保存模型
local UiModelTransformTemplates = {} -- Ui模型位置配置表
local UiSceneTransformTemplates = {} -- Ui模型位置配置表
local ModelTemplates = {} -- 模型相关配置
local UIModelTemplates = {} -- UI模型相关配置
local LuaBehaviourDict = {} -- 武器生命周期对象

--角色Model配置表
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
    local config = UIModelTemplates[modelId]--UI模型配置
    or ModelTemplates[modelId]--战斗模型配置（保底配置）
    if not config then
        XLog.Error("XModelManager GetUiModelConfig error: 模型配置不存在, modelId: " .. modelId .. " ,配置路径: " .. UIMODEL_TABLE_PATH)
        return
    end
    return config
end

local function GetModelConfig(modelId)
    local config = ModelTemplates[modelId]--战斗模型配置
    if not config then
        XLog.Error("XModelManager GetModelConfig error: 模型配置不存在, modelId: " .. modelId .. " ,配置路径: " .. MODEL_TABLE_PATH)
        return
    end
    return config
end

------UI调用 begin --------
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

--特殊时装会用到的动画状态机路径
function XModelManager.GetUiFashionControllerPath(modelId)
    local config = GetUiModelConfig(modelId)
    return config.FashionControllerPath
end
------UI调用 end --------
------战斗C#调用 begin --------
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
------战斗C#调用 end --------
function XModelManager.GetRoleModelConfig(uiName, modelName)
    if not uiName or not modelName then
        XLog.Error("XModelManager.GetRoleMoadelConfig 函数错误: 参数uiName和modelName都不能为空")
        return
    end

    if UiModelTransformTemplates[uiName] then
        return UiModelTransformTemplates[uiName][modelName]
    end
end

function XModelManager.GetSceneModelConfig(uiName, sceneUrl)
    if not uiName or not sceneUrl then
        XLog.Error("XModelManager.GetSceneModelConfig 函数错误: 参数uiName和sceneUrl都不能为空")
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

--新UI框架
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
    --检查数据 模型旋转
    target.transform.localEulerAngles = CS.UnityEngine.Vector3(config.RotationX, config.RotationY, config.RotationZ)
    --检查数据 模型大小
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
    XLog.Warning(animator.runtimeAnimatorController.name .. "  不存在動作ID：" .. actionName)
    return false
end

---=================================================
--- 在当前播放中的动画播放完后执行回调
---@overload fun(callBack:function)
---@param callBack function
---=================================================
local CheckAnimeFinish = function(animator, behaviour, animaName, callBack)--如果动画被打断或是停止都会调用回调
    local animatorInfo = animator:GetCurrentAnimatorStateInfo(0)
    if (animatorInfo:IsName(animaName) and animatorInfo.normalizedTime >= 1) or not animatorInfo:IsName(animaName) then--normalizedTime的值为0~1，0为开始，1为结束。
        if callBack then callBack() end
        behaviour.enabled = false
    end
end

local AddPlayingAnimCallBack = function(obj, animator, animaName, callBack)
    local animatorInfo = animator:GetCurrentAnimatorStateInfo(0)

    if not animatorInfo:IsName(animaName) or animatorInfo.normalizedTime >= 1 then--normalizedTime的值为0~1，0为开始，1为结束。
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
--- 播放'AnimaName'动画，‘fromBegin’决定动画是否需要调整到从0开始播放，默认值为false
---@overload fun(AnimaName:string)
---@param obj 场景对象
---@param animator Animator组件
---@param animaName string
---@param fromBegin boolean
---@param callBack function 播放成功回调
---@param finishCallBack function 播放成功且播放完之后的回调
---@param errorCb function 失败之后的回调
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
--@param: 武器模型id列表
--      showEffect 显示特效
--      gameObject 用于绑定生命周期
--      noShowing  不需要变形（变形动画、变形音效、循环动画）
--      noRotation 不需要自转
--      usage      武器用途(XEquipConfig.WeaponUsage)
--      noSound    不需要声音
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

    if not param or not param.showEffect then  -- 默认显示特效
        local effectPath = XEquipConfig.GetEquipModelEffectPath(modelId, usage)
        XModelManager.LoadWeaponEffect(model, effectPath)
    end

    local gameObject = param and param.gameObject
    XModelManager.PlayWeaponShowing(model, modelId, uiName, gameObject, param)

    -- 自转逻辑
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

-- 播放变形动画及音效
--  param参数见 XModelManager.LoadWeaponModel
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

        -- 切换动作状态机前 先停止音效
        local equipModelObj = XModelManager.GetLuaBehaviour(go)
        if equipModelObj then
            equipModelObj:ClearAudioInfo()
        end
    end

    --某些特殊类型无视关闭动画效果
    if notCareNoAnim then
    else
        if noShowing then
            return
        end
    end

    local playSound = true
    -- 武器动画逻辑：静止 - 展开 - 待机循环（默认）
    local animStateName = XEquipConfig.GetEquipUiAnimStateName(modelId, usage)
    if animStateName then
        animator = animator or target:GetComponent("Animator")
        if animator and XModelManager.CheckAnimatorAction(animator, animStateName) then
            -- 静止
            animator:Play(animStateName)
            -- 展开
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
    if not go then -- 音效需要gameObject绑定生命周期
        return
    end

    local animCueId = XEquipConfig.GetEquipUiAnimCueId(modelId, usage)
    if animCueId and animCueId ~= 0 then
        local audioInfo = CS.XAudioManager.PlaySound(animCueId) -- 音效
        XModelManager.AddAudioInfo(go, audioInfo)
    end
end

-- 记录模型音效，跟随gameObject生命周期
function XModelManager.AddAudioInfo(go, audioInfo)
    local equipModelObj = XModelManager.GetOrCreateLuaBehaviour(go)
    equipModelObj:AddAudioInfo(audioInfo)
end

-- 武器共鸣特效
function XModelManager.LoadWeaponEffect(model, effectPath)
    if not effectPath then return end
    if XTool.UObjIsNil(model) then return end

    local target = model.transform:FindTransform("WeaponCenter")
    if XTool.UObjIsNil(target) then return end

    target:LoadPrefab(effectPath, false)
end

--==============================--
--desc: 加载角色武器
--@roleModel: 角色模型
--@equipModelIdList: 武器模型id列表
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

    -- 如果不加载武器，则直接执行CallBack
    if #equipModelIdList <= 0 and cb then
        cb()
    end
end

-- 根据FightNpcData创建武器模型及其特效
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
--desc:  为装备添加XLuaBehaviour，用于生命周期管理
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