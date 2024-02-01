XModelManager = XModelManager or {}

local Ui_MODEL_TRANSFORM_PATH = "Client/Ui/UiModelTransform.tab"
local Ui_SCENE_TRANSFORM_PATH = "Client/Ui/UiSceneTransform.tab"
local MODEL_TABLE_PATH = "Client/ResourceLut/Model/Model.tab"
local UIMODEL_TABLE_PATH = "Client/ResourceLut/Model/UIModel.tab"
local DLC_MODEL_TABLE_PATH = "Client/StatusSyncFight/ResourceLut/Model/Model.tab"
local SPECIAL_UIMODEL_PATH = "Client/ResourceLut/Model/SpecialUiModel.tab"
local Ui_MODEL_CAMERA_PATH = "Client/Ui/UiModelCamera.tab"
local UI_MODEL_NODE_ACTIVE_PATH = "Client/Ui/UiModelBoneActive.tab"
local UI_MODEL_OFF_WEAPON_BONE_BIND = "Client/Ui/UiModelOffWeaponBoneBind.tab"
local UI_SPECIAL_MODEL_CAMERA_PATH = "Client/Ui/UiSpecialModelCamera.tab"
local XEquipModel = require("XEntity/XEquip/XEquipModel")
local Vector3 = CS.UnityEngine.Vector3


local function _SetActive(model, nodes, active)
    nodes = nodes or {}
    for _, name in ipairs(nodes) do
        local go = model:FindTransform(name)
        if not XTool.UObjIsNil(go) then
            go.gameObject:SetActiveEx(active)
        end
    end
end

XModelManager.MODEL_ROTATION_VALUE = 10

XModelManager.MODEL_UINAME = {
    XUiMain = "UiMain",
    XUiCharacter = "UiCharacter",
    XUiCharacterV2P6 = "UiCharacterV2P6",
    XUiCharacterSystemV2P6 = "UiCharacterSystemV2P6",
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
    XUiSameColorGameBoss = "UiSameColorGameBoss",
    XUiSameColorGameBattle = "UiSameColorGameBattle",
    XUiSuperSmashBrosCharacter = "UiSuperSmashBrosCharacter",
    XUiAreaWarBoss = "UiAreaWarBoss",
    UiReviewActivityAnniversary = "UiReviewActivityAnniversary",
    XUiConsumeActivityLuckyBag = "UiConsumeActivityLuckyBag",
    XUiGoldenMinerMain3D = "UiGoldenMinerMain3D",
    XUiMultiDimMain = "UiMultiDimMain",
    UiBrilliantWalkMain = "UiBrilliantWalkMain",
}

--local RoleModelPool = {} --保存模型
local UiModelTransformTemplates = {} -- Ui模型位置配置表
local UiModelCameraTemplates = {} -- Ui模型相机配置表
local UiSpecialModelCameraTemplates = {} -- Ui特殊模型相机配置表
local UiSceneTransformTemplates = {} -- Ui模型位置配置表
local ModelTemplates = {} -- 模型相关配置
local UIModelTemplates = {} -- UI模型相关配置
local DlcModelTemplates = {} --Dlc 模型
local SpecialUiModel = {}
local LuaBehaviourDict = {} -- 武器生命周期对象
local CameraDefaultDic = {} -- 相机默认参数字典
local UiModelNodeActiveMap = {} --uiName + modelId -> Id
local UiModelWeaponBindTemplates = nil --特定模型关闭武器绑定角色骨骼

--角色Model配置表
function XModelManager.Init()
    ModelTemplates = XTableManager.ReadByStringKey(MODEL_TABLE_PATH, XTable.XTableModel, "Id")
    UIModelTemplates = XTableManager.ReadByStringKey(UIMODEL_TABLE_PATH, XTable.XTableUiModel, "Id")
    DlcModelTemplates = XTableManager.ReadByStringKey(DLC_MODEL_TABLE_PATH, XTable.XTableUiModel, "Id")
    local specialModels = XTableManager.ReadAllByIntKey(SPECIAL_UIMODEL_PATH, XTable.XTableSpecialUiModel, "Id")
    for _, cfg in pairs( (specialModels or {})) do
        if not SpecialUiModel[cfg.ModelId] then
            SpecialUiModel[cfg.ModelId] = {}
        end
        if not cfg.MainModelId and not cfg.MinorModelId then
            XLog.Error("SpecialUiModel Init Error, MainModelId 与 MinorModelId 不能全为空. ModelId = "..id..",配置路径:"..SPECIAL_UIMODEL_PATH)
            return
        end
        SpecialUiModel[cfg.ModelId][cfg.UiName] = cfg
    end

    UiModelTransformTemplates = {}
    UiSceneTransformTemplates = {}

    local tab = XTableManager.ReadAllByIntKey(Ui_MODEL_TRANSFORM_PATH, XTable.XTableUiModelTransform, "Id")
    for _, config in pairs(tab) do
        if not UiModelTransformTemplates[config.UiName] then
            UiModelTransformTemplates[config.UiName] = {}
        end
        UiModelTransformTemplates[config.UiName][config.ModelName] = config
    end

    local sceneTab = XTableManager.ReadAllByIntKey(Ui_SCENE_TRANSFORM_PATH, XTable.XTableUiSceneTransform, "Id")
    for _, config in pairs(sceneTab) do
        if not UiSceneTransformTemplates[config.UiName] then
            UiSceneTransformTemplates[config.UiName] = {}
        end
        UiSceneTransformTemplates[config.UiName][config.SceneUrl] = config
    end

    local cameraTab = XTableManager.ReadAllByIntKey(Ui_MODEL_CAMERA_PATH, XTable.XTableUiModelCamera, "Id")
    for _, config in pairs(cameraTab) do
        if not UiModelCameraTemplates[config.UiName] then
            UiModelCameraTemplates[config.UiName] = {}
        end
        if not UiModelCameraTemplates[config.UiName][config.ModelName] then
            UiModelCameraTemplates[config.UiName][config.ModelName] = {}
        end
        table.insert(UiModelCameraTemplates[config.UiName][config.ModelName], config)
    end

    local specialCameraTab = XTableManager.ReadAllByIntKey(UI_SPECIAL_MODEL_CAMERA_PATH, XTable.XTableUiSpecialModelCamera, "Id")
    for _, config in pairs(specialCameraTab) do
        if not UiSpecialModelCameraTemplates[config.UiName] then
            UiSpecialModelCameraTemplates[config.UiName] = {}
        end
        if not UiSpecialModelCameraTemplates[config.UiName][config.CharacterId] then
            UiSpecialModelCameraTemplates[config.UiName][config.CharacterId] = {}
        end
        table.insert(UiSpecialModelCameraTemplates[config.UiName][config.CharacterId], config)
    end

    UiModelNodeActiveMap = {}
    local uiModelNodeActive = XTableManager.ReadByIntKey(UI_MODEL_NODE_ACTIVE_PATH, XTable.XTableUiModelBoneActive, "Id")
    for _, template in pairs(uiModelNodeActive) do
        local actionId, modelId = template.ActionId, template.ModelName
        UiModelNodeActiveMap[actionId] = UiModelNodeActiveMap[actionId] or {}
        UiModelNodeActiveMap[actionId][modelId] = template
    end
end

local function GetUiModelOffWeaponBoneBindConfigs()
    if not UiModelWeaponBindTemplates then
        UiModelWeaponBindTemplates = XTableManager.ReadByStringKey(UI_MODEL_OFF_WEAPON_BONE_BIND, XTable.XTableUiModelOffWeaponBoneBind, "ModelId")
    end

    return UiModelWeaponBindTemplates
end

---@return XTableUiModelOffWeaponBoneBind
local function GetUiModelOffWeaponBoneBindConfig(modelId)
    local configs = GetUiModelOffWeaponBoneBindConfigs()
    
    if not configs then
        return {}
    end

    return configs[modelId]
end

local function GetUiModelConfig(modelId)
    local config = UIModelTemplates[modelId]--UI模型配置
    or ModelTemplates[modelId]--战斗模型配置（保底配置）
    or DlcModelTemplates[modelId] --DLC模型
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

--==============================
---@desc 检查是否为特殊模型
---@modelId 模型id
---@uiName  加载模型的UIName
---@return boolean 是否为特殊模型
---@return boolean 是否为多重模型
--==============================
function XModelManager.CheckModelIsSpecial(modelId, uiName)
    local specCfg = SpecialUiModel[modelId]
    local isMultiModel = false
    if specCfg then
        local uiName2Cfg = specCfg[uiName] and specCfg[uiName] or specCfg["Default"]
        if not uiName2Cfg then
            return true, false
        end
        isMultiModel = uiName2Cfg and (uiName2Cfg.MainModelId and uiName2Cfg.MinorModelId) or false
    end
    return specCfg and true or false, isMultiModel
end

--==============================
---@desc 获取需要特殊加载的模型Id, 优先级：MinorModelId > MainModelId
---@modelId 模型id
---@uiName  加载模型的UIName
---@return string 需要特殊加载的模型Id
--==============================
function XModelManager.GetSpecialModelId(modelId, uiName)
    local specCfg = SpecialUiModel[modelId]
    if specCfg then
        local uiName2Cfg = specCfg[uiName] and specCfg[uiName] or specCfg["Default"]
        if not uiName2Cfg then
            return modelId
        end
        return uiName2Cfg.MinorModelId and uiName2Cfg.MinorModelId or uiName2Cfg.MainModelId
    end
    return modelId
end

--==============================
---@desc 获取次级模型
---@modelId 模型id
---@uiName  加载模型的UIName
---@return nil or modelId
--==============================
function XModelManager.GetMinorModelId(modelId, uiName)
    local specCfg = SpecialUiModel[modelId]
    if specCfg then
        local uiName2Cfg = specCfg[uiName]
        if not uiName2Cfg then
            uiName2Cfg = specCfg["Default"]
            if not uiName2Cfg then return nil end
            return uiName2Cfg.MinorModelId and uiName2Cfg.MinorModelId or nil
        end
        return uiName2Cfg.MinorModelId
    end
    return nil
end

--- 处理Ui模型上节点的显隐
---@param actionName string
---@param modelId string
---@param model UnityEngine.GameObject
---@param isActive boolean
--------------------------
function XModelManager.HandleUiModelNodeActive(actionName, modelId, model, isActive)
    local isHide, hideNodes, showNodes = XModelManager.CheckUiModelNodeActive(actionName, modelId, model)
    
    if isHide then
        isActive = isActive or false
        _SetActive(model, hideNodes, isActive)
        _SetActive(model, showNodes, not isActive)
    end
    
    return isHide
end

--- 检查Ui模型上节点的显隐
---@param actionName string
---@param modelId string
---@param model UnityEngine.GameObject
--------------------------
function XModelManager.CheckUiModelNodeActive(actionName, modelId, model)
    if XTool.UObjIsNil(model) or string.IsNilOrEmpty(actionName) or string.IsNilOrEmpty(modelId) then
        return false
    end
    local map = UiModelNodeActiveMap[actionName]
    if XTool.IsTableEmpty(map) then
        return false
    end
    local template = map[modelId]
    if not template then
        return false
    end
    local hideNodes, showNodes = template.HideNodes, template.ShowNodes

    if not XTool.IsTableEmpty(hideNodes) or not XTool.IsTableEmpty(showNodes) then
        return true, hideNodes, showNodes
    else
        return false
    end
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

function XModelManager.GetControllerPath(modelId, level)
    local config = GetModelConfig(modelId)
    if level and level > 0 then
        if config.LevelControllerPath and config.LevelControllerPath[level] then
            return config.LevelControllerPath[level]
        else
            XLog.Error("Model:" .. modelId .. " doesnt has levelController:" .. level .." please check Client\\ResourceLut\\Model\\Model.tab")
        end
    end
    return config.ControllerPath
end
------战斗C#调用 end --------
function XModelManager.GetRoleModelConfig(uiName, modelName)
    if not uiName or not modelName then
        XLog.Error("XModelManager.GetRoleModelConfig 函数错误: 参数uiName和modelName都不能为空")
        return
    end

    if UiModelTransformTemplates[uiName] then
        return UiModelTransformTemplates[uiName][modelName]
    end
end

-- 获取相机配置信息
---@param uiName string UI名
---@param modelName string 模型名
---@param characterId number 角色Id
function XModelManager.GetRoleCameraConfigList(uiName, modelName, characterId)
    local templates = XModelManager.GetModelCameraTemplates(uiName, modelName)
    if XTool.IsTableEmpty(templates) then
        -- 没有找到对应的模型相机配置，使用特殊模型相机配置
        templates = XModelManager.GetSpecialModelCameraTemplates(uiName, characterId)
    end
    return templates
end

-- 获取模型相机配置
---@param uiName string UI名
---@param modelName string 模型名
function XModelManager.GetModelCameraTemplates(uiName, modelName)
    if not uiName or not modelName then
        XLog.Error("XModelManager.GetModelCameraTemplates 函数错误: 参数uiName和modelName都不能为空")
        return
    end
    if UiModelCameraTemplates[uiName] then
        return UiModelCameraTemplates[uiName][modelName]
    end
    return nil
end

-- 获取特殊模型相机配置
---@param uiName string UI名
---@param characterId number 角色Id
function XModelManager.GetSpecialModelCameraTemplates(uiName, characterId)
    if not uiName then
        XLog.Error("XModelManager.GetSpecialModelCameraTemplates 函数错误: 参数uiName不能为空")
        return
    end
    if UiSpecialModelCameraTemplates[uiName] then
        if not XTool.IsNumberValid(characterId) then
            XLog.Error("XModelManager.GetSpecialModelCameraTemplates 函数错误: 参数characterId不能为空")
            return
        end
        return UiSpecialModelCameraTemplates[uiName][characterId]
    end
    return nil
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
function XModelManager.LoadRoleModel(modelId, target, cb)
    if not modelId or not target then
        return
    end

    local modelPath = XModelManager.GetUiModelPath(modelId)
    local model = CS.LoadHelper.InstantiateNpc(modelPath)
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

local setModelCamera = function(target, config)
    if not target or not config then
        return
    end
    
    if config.FieldOfView > 0 then
        ---@type Cinemachine.CinemachineVirtualCamera
        local virtualCamera = target.gameObject:GetComponent("CinemachineVirtualCamera")
        if XTool.UObjIsNil(virtualCamera) then
            XLog.Error(string.format("未能找到虚拟相机组件, 相机名：%s 模型名：%s", target.gameObject.name, config.ModelName))
        else
            local newLens = virtualCamera.m_Lens
            newLens.FieldOfView = config.FieldOfView
            virtualCamera.m_Lens = newLens
        end
    end

    target.transform.localPosition = CS.UnityEngine.Vector3(config.PositionX, config.PositionY, config.PositionZ)
    target.transform.localEulerAngles = CS.UnityEngine.Vector3(config.RotationX, config.RotationY, config.RotationZ)
end

--- 复原虚拟相机设置
---@param target UnityEngine.GameObject 虚拟相机节点
---@param position UnityEngine.Vector3 相机位置
---@param rotation UnityEngine.Quaternion 相机旋转四元数
---@param fov number 视角大小
--------------------------
local restoreCamera = function(target, position, rotation, fov, eulerAngles)
    if XTool.UObjIsNil(target) then
        return
    end

    target.transform.position = position
    target.transform.rotation = rotation
    target.transform.rotation.eulerAngles = eulerAngles
    local virtualCamera = target.gameObject:GetComponent("CinemachineVirtualCamera")
    if XTool.UObjIsNil(virtualCamera) then
        return
    end
    
    local newLens = virtualCamera.m_Lens
    newLens.FieldOfView = fov
    virtualCamera.m_Lens = newLens
end

--- 获取虚拟相机的视角大小
---@param target UnityEngine.GameObject 虚拟相机节点
---@return number
--------------------------
local getVirtualCameraFov = function(target)
    if XTool.UObjIsNil(target) then
        return
    end
    
    local virtualCamera = target.gameObject:GetComponent("CinemachineVirtualCamera")
    if XTool.UObjIsNil(virtualCamera) then
        return
    end
    
    return virtualCamera.m_Lens.FieldOfView
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

---@type table<string, UnityEngine.Transform>
local curCamRoot = { }
function XModelManager.SetRoleCamera(name, cameraRoot, uiName, characterId)
    if not uiName or XTool.UObjIsNil(cameraRoot) then
        return
    end

    -- 标记场景有没有重载，如果镜头节点重载了重置默认镜头参数
    if XTool.UObjIsNil(curCamRoot[uiName]) or curCamRoot[uiName] ~= cameraRoot and cameraRoot.name ~= "UiNearRoot" then
        curCamRoot[uiName] = cameraRoot
        CameraDefaultDic[uiName] = nil
    end

    for cameraName, cameraDefault in pairs(CameraDefaultDic[uiName] or {}) do
        local camera = cameraRoot:FindTransform(cameraName)
        if camera then
            restoreCamera(camera, cameraDefault.Position, cameraDefault.Rotation, cameraDefault.VirtualFov, cameraDefault.EulerAngles)
        end
    end
    CameraDefaultDic[uiName] = nil

    local configList = XModelManager.GetRoleCameraConfigList(uiName, name, characterId)
    if not configList or not next(configList) then
        return
    end

    for _,config in pairs(configList or {}) do
        local camera = cameraRoot:FindTransform(config.CameraName)
        if camera then
            CameraDefaultDic[uiName] = CameraDefaultDic[uiName] or {}
            if not CameraDefaultDic[uiName][config.CameraName] then
                CameraDefaultDic[uiName][config.CameraName] = {
                    Position = camera.transform.position,
                    Rotation = camera.transform.rotation,
                    EulerAngles = camera.transform.rotation.eulerAngles,
                    VirtualFov = getVirtualCameraFov(camera)
                }
            end
            setModelCamera(camera, config)
        end
    end
end

function XModelManager.CheckAnimatorAction(animator, actionName)
    if not actionName then
        return false
    end
    if not (animator and animator:Exist() and animator.runtimeAnimatorController and animator.gameObject.activeInHierarchy) then
        return false
    end

    -- Animator.Play使用的是状态机里的stateName，而不是资源动作名
    --local animationClips = animator.runtimeAnimatorController.animationClips
    --for i = 0, animationClips.Length - 1 do
    --    local tempClip = animationClips[i]
    --    if tempClip:Exist() and tempClip.name == actionName then
    --        return true
    --    end
    --end
    --XLog.Warning(animator.runtimeAnimatorController.name .. "  不存在動作ID：" .. actionName)
    --return true

    local stateId = CS.UnityEngine.Animator.StringToHash(actionName)
    local layer = 0
    if not animator:HasState(layer, stateId) then
        XLog.Warning(animator.runtimeAnimatorController.name .. "  不存在動作ID：" .. actionName)
        return false
    end
    return true
end

--==============================--
--装备模型节点显示控制
function XModelManager.DoEquipModelControl(modelId, uiName, model)
    local hideNodeName = XEquipConfig.GetEquipModelShowHideNodeName(modelId, uiName)
    if not XTool.IsTableEmpty(hideNodeName) then
        for _, nodeName in pairs(hideNodeName) do
            local parts = model.transform:FindTransform(nodeName)
            if not XTool.UObjIsNil(parts) then
                parts.gameObject:SetActiveEx(false)
            else
                XLog.Error("DoEquipModelControl NodeName Is Wrong :" .. nodeName)
            end
        end
    end
end

--@param: 武器模型id列表
--      showEffect 显示特效
--      gameObject 用于绑定生命周期
--      noShowing  不需要变形（变形动画、变形音效、循环动画）
--      noRotation 不需要自转
--      usage      武器用途(XEquipConfig.WeaponUsage)
--      noSound    不需要声音
function XModelManager.LoadWeaponModel(modelId, target, transformConfig, uiName, cb, param, panelDrag)
    if not modelId or modelId == 0 or XTool.UObjIsNil(target) then
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

    -- 旋转逻辑
    if gameObject and not (param and param.noRotation) then
        if (param.IsDragRotation) then
            XModelManager.DragRotateWeapon(panelDrag, model, modelId, gameObject, nil, nil, param.AntiClockwise)
        else
            XModelManager.AutoRotateWeapon(target, model, modelId, gameObject)
        end

    end
    XModelManager.DoEquipModelControl(modelId, uiName, model)

    if cb then
        cb(model)
    end
end

function XModelManager.AutoRotateWeapon(target, model, modelId, go, notWeapon, center)
    local equipModelObj = XModelManager.GetOrCreateLuaBehaviour(go)
    equipModelObj:AutoRotateWeapon(target, model, modelId, notWeapon, center)
end

function XModelManager.DragRotateWeapon(panelDrag, model, modelId, go, notWeapon, center, antiClockwise)
    local equipModelObj = XModelManager.GetOrCreateLuaBehaviour(go)
    equipModelObj:DragRotateWeapon(panelDrag, model, modelId, center, notWeapon, antiClockwise)
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
            animator:Update(0)
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
function XModelManager.LoadRoleWeaponModel(roleModel, equipModelIdList, refName, cb, hideEffect, go, roleModelId, equipUsage)
    if not roleModel then
        return
    end

    local isShowing = (XDataCenter.SetManager.WeaponTransType == XSetConfigs.WeaponTransEnum.Open)
    
    local newCb = function(model)
        --新角色，武器同步骨骼
        local component = model.gameObject:GetComponent(typeof(CS.XBoneTransformSync))
        if component then
            component:SetTarget(roleModel.transform)
        end
        if cb then cb(model) end
    end
    
    local usage = XEquipConfig.WeaponUsage.Role

    if equipUsage and equipUsage > 0 then
        usage = equipUsage
    end

    local specialCaseName = XUiHelper.GetClientConfig("UiSpecialWeaponCase", XUiHelper.ClientConfigType.String)
    local specialCase = roleModel.transform:FindTransform(specialCaseName)
    local caseNode = nil
    if not XTool.UObjIsNil(specialCase) then
        caseNode = XUiHelper.GetClientConfig("UiWeaponCaseNode", XUiHelper.ClientConfigType.String)
    else
        caseNode = XUiHelper.GetClientConfig("WeaponCaseNode", XUiHelper.ClientConfigType.String)
    end
    for i = 1, #equipModelIdList do
        local modelId = equipModelIdList[i]
        if modelId and modelId ~= 0 then
            local weaponCase = roleModel.transform.FindTransform(roleModel.transform, caseNode .. i)  
            if not weaponCase then
                XLog.Warning("XModelManager.LoadRoleWeaponModel warning, " .. caseNode .. i .. " not found")
            else
                XModelManager.LoadWeaponModel(modelId, weaponCase, nil, refName, newCb, {
                    showEffect = not hideEffect, noShowing = not isShowing, noRotation = true,
                    usage = usage, gameObject = go, noSound = true, roleModelId = roleModelId
                })
            end
        end
    end

    -- 如果不加载武器，则直接执行CallBack
    if #equipModelIdList <= 0 and cb then
        cb()
    end
end

-- 根据FightNpcData创建武器模型及其特效
function XModelManager.LoadRoleWeaponModelByFight(roleModel, fightNpcData, refName, go, roleModelId, cb)
    if not roleModel then
        return
    end

    local isShowing = (XDataCenter.SetManager.WeaponTransType == XSetConfigs.WeaponTransEnum.Open)

    local newCb = function(model)
        --新角色，武器同步骨骼
        local component = model.gameObject:GetComponent(typeof(CS.XBoneTransformSync))
        if component then
            component:SetTarget(roleModel.transform)
        end
        if cb then cb(model) end
    end

    local usage = XEquipConfig.WeaponUsage.Role
    local idList = XDataCenter.EquipManager.GetEquipModelIdListByFight(fightNpcData)
    local specialCaseName = XUiHelper.GetClientConfig("UiSpecialWeaponCase", XUiHelper.ClientConfigType.String)
    local specialCase = roleModel.transform:FindTransform(specialCaseName)
    local caseNode = nil
    if not XTool.UObjIsNil(specialCase) then
        caseNode = XUiHelper.GetClientConfig("UiWeaponCaseNode", XUiHelper.ClientConfigType.String)
    else
        caseNode = XUiHelper.GetClientConfig("WeaponCaseNode", XUiHelper.ClientConfigType.String)
    end
    for i, modelId in ipairs(idList) do
        local weaponCase = roleModel.transform.FindTransform(roleModel.transform, caseNode .. i)
        if not weaponCase then
            XLog.Warning("XModelManager.LoadRoleWeaponModel warning, " .. caseNode .. i .. " not found")
        else
            XModelManager.LoadWeaponModel(modelId, weaponCase, nil, refName, newCb, { noShowing = not isShowing, noRotation = true, usage = usage, gameObject = go, noSound = true, roleModelId = roleModelId })
        end
    end

    -- 如果不加载武器，则直接执行CallBack
    if #idList <= 0 and cb then
        cb()
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

--region 部分模型需要根据动作屏蔽武器绑定骨骼XBoneTransformSync脚本
function XModelManager.CheckWeaponNeedBindBone(modelId)
    if not modelId then
        return
    end 
    
    local config = GetUiModelOffWeaponBoneBindConfig(modelId)

    if not config then
        return true
    end

    return config.IsOffBindBone ~= 1
end

function XModelManager.GetWeaponUnBindBoneActionIsList(modelId)
    local config = GetUiModelOffWeaponBoneBindConfig(modelId)

    if not config then
        return {}
    end

    return config.ActionId or {}
end

function XModelManager.GetWeaponUnBindModelCaseList(modelId)
    local config = GetUiModelOffWeaponBoneBindConfig(modelId)

    if not config then
        return {}
    end

    return config.WeaponCaseName or {}
end 

function XModelManager.WaeponUnBindModelBone(modelId, model, actionId)
    if XModelManager.CheckWeaponNeedBindBone(modelId) then
        return
    end

    local actionIds = XModelManager.GetWeaponUnBindBoneActionIsList(modelId)
    local weaponCaseList = XModelManager.GetWeaponUnBindModelCaseList(modelId)
    local isActive = true

    for i = 1, #actionIds do
        if actionId == actionIds[i] then
            isActive = false
        end
    end

    for _, weaponCase in ipairs(weaponCaseList) do
        local case = model.transform:FindTransform(weaponCase)

        if not case then
            XLog.Warning("XModelManager.WaeponUnBindModelBone warning, " .. weaponCase .. " not found")
        else
            local component = case.gameObject:GetComponentsInChildren(typeof(CS.XBoneTransformSync))

            if component then
                for i = 0, component.Length - 1 do
                    component[i].enabled = isActive
                end
            end
        end
    end
end
--endregion