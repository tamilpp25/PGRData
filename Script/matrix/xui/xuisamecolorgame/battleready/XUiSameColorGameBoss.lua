local XUiSameColorGamePanelBoss = require("XUi/XUiSameColorGame/BattleReady/XUiSameColorGamePanelBoss")
local XUiSameColorGamePanelRole = require("XUi/XUiSameColorGame/BattleReady/XUiSameColorGamePanelRole")
local XUiSameColorGamePanelReady = require("XUi/XUiSameColorGame/BattleReady/XUiSameColorGamePanelReady")
local XUiSameColorGamePanelMain = require("XUi/XUiSameColorGame/BattleReady/XUiSameColorGamePanelMain")
---@class XUiSameColorGameBoss:XLuaUi
---@field _Control XSameColorControl
local XUiSameColorGameBoss = XLuaUiManager.Register(XLuaUi, "UiSameColorGameBoss")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

function XUiSameColorGameBoss:OnAwake()
    self.SameColorGameManager = XDataCenter.SameColorActivityManager
    self.RoleManager = self.SameColorGameManager.GetRoleManager()
    ---@type XSCBoss
    self.CurrentBoss = nil
    ---@type XSCRole
    self.LastSelectableRole = nil
    ---@type XSCRole
    self.CurrentRole = nil
    -- 模型
    local uiModel, uiModelGo, uiSceneInfo = self.SameColorGameManager.GetMainUiModelInfo()
    local uiNearRootObj = uiModel.UiNearRoot:GetComponent("UiObject")
    uiModelGo.gameObject:SetActiveEx(true)
    uiSceneInfo.GameObject:SetActiveEx(false)
    uiSceneInfo.GameObject:SetActiveEx(true)
    self.UiModel = uiModel
    
    self:InitSceneModel(uiNearRootObj)
    self:InitSceneCamera(uiNearRootObj)
    self:InitChildPanel()
    self:InitPanelAsset()
    self:AddBtnListener()
end

function XUiSameColorGameBoss:OnStart(boss)
    self.CurrentBoss = boss
    
    self:InitSelectRole()
    self:InitAutoClose()
    self:UpdateBossModel(self.CurrentBoss)
    self:UpdateRoleModel(self.CurrentRole)

    -- 检查是否打开初始角色获取界面（三期隐藏不打开）
    --self:CheckGetNewRoleTip()
end

function XUiSameColorGameBoss:OnEnable()
    XUiSameColorGameBoss.Super.OnEnable(self)
    if self.CurrentChildType == XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE.ROLE then
        local lastRoleId = self.LastSelectableRole:GetId()
        self:UpdateChildPanel(self.CurrentChildType)
        self.LastSelectableRole = self.RoleManager:GetRole(lastRoleId)
        self:SetIsSelected(lastRoleId == self.CurrentRole:GetId())
        self:UpdateReadyBtnStatus()
    elseif self.CurrentChildType == XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE.MAIN then
        -- 因为5期添加了MAIN -> READY动画
        -- 会导致进入战斗后boss节点被上述动画影响错位
        -- 因此需要切换到READY -> MAIN动画的最后一帧保持
        local panelType = XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE
        ---@type UnityEngine.Playables.PlayableDirector
        local animReadyBack = self.NearCameraAnimDic[panelType.READY][panelType.MAIN]
        if animReadyBack.state ~= CS.Playable.PlayState.Playing and animReadyBack.time <= animReadyBack.duration then
            animReadyBack:Play()
            animReadyBack.time = animReadyBack.duration
        end
        self:UpdateChildPanel(self.CurrentChildType)
        self:UpdateReadyBtnStatus()
    else
        self:UpdateChildPanel(self.CurrentChildType)
        self:UpdateReadyBtnStatus()
    end
end

function XUiSameColorGameBoss:OnDestroy()
    self:Clear()
    XUiSameColorGameBoss.Super.OnDestroy(self)
end

function XUiSameColorGameBoss:SetBtnChange()
    self.BtnChange.gameObject:SetActiveEx(true)
end

function XUiSameColorGameBoss:UpdateReadyBtnStatus()
    local isLock = self.CurrentRole:GetIsLock()
    self.BtnReady:SetButtonState(isLock and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

--region Ui - AutoClose
function XUiSameColorGameBoss:InitAutoClose()
    local endTime = self.SameColorGameManager.GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self.SameColorGameManager.HandleActivityEndTime()
        end
    end)
end
--endregion

--region Ui - PanelAsset
function XUiSameColorGameBoss:InitPanelAsset()
    local itemIds = self._Control:GetCfgAssetItemIds()
    XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelAsset, self, nil , function(uiSelf, index)
        local itemId = itemIds[index]
        XLuaUiManager.Open("UiSameColorGameSkillDetails", nil, itemId)
    end)
end
--endregion

--region Ui - ChildPanel
function XUiSameColorGameBoss:InitChildPanel()
    local childPanelType = XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE
    -- 页面显示数据
    local transformDic = {{}, {}, {}, {}}
    local mainCameraTime = XCameraHelper.GetBlendTime(self.CameraBrain, childPanelType.MAIN - 1)
    transformDic[childPanelType.BOSS][childPanelType.MAIN] = mainCameraTime - 0.1
    transformDic[childPanelType.ROLE][childPanelType.MAIN] = mainCameraTime - 0.3
    self.TransformDic = transformDic
    -- 子页面配置
    self.ChildPanelInfoDic = {
        [childPanelType.MAIN] = {
            uiParent = self.PanelMain,
            proxy = XUiSameColorGamePanelMain,
            assetPath = XUiConfigs.GetComponentUrl("UiSameColorPanelMain"),
            proxyArgs = { "CurrentBoss", "CurrentRole" }
        },
        [childPanelType.ROLE] = {
            uiParent = self.PanelRole,
            proxy = XUiSameColorGamePanelRole,
            assetPath = XUiConfigs.GetComponentUrl("UiSameColorPanelRole"),
            proxyArgs = { "CurrentRole", "CurrentBoss" }
        },
        [childPanelType.BOSS] = {
            uiParent = self.PanelBoss,
            proxy = XUiSameColorGamePanelBoss,
            assetPath = XUiConfigs.GetComponentUrl("UiSameColorPanelBoss"),
            proxyArgs = { "CurrentBoss" }
        },
        [childPanelType.READY] = {
            uiParent = self.PanelReady,
            proxy = XUiSameColorGamePanelReady,
            assetPath = XUiConfigs.GetComponentUrl("UiSameColorPanelReady"),
            proxyArgs = { "CurrentRole", "CurrentBoss" }
        },
    }
    -- 当前页面状态
    self.CurrentChildType = XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE.MAIN
end

---@param panelType number XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE
function XUiSameColorGameBoss:UpdateChildPanel(panelType)
    local fromChildType = self.CurrentChildType
    XScheduleManager.ScheduleOnce(function()
        self:SetCameraType(panelType, fromChildType)
    end, 1)
    self.CurrentChildType = panelType
    for key, data in pairs(self.ChildPanelInfoDic) do
        if data.instanceProxy and CheckClassSuper(data.instanceProxy, XUiNode) then
            if key == panelType then
                data.instanceProxy:Open()
            else
                data.instanceProxy:Close()
            end
        else
            data.uiParent.gameObject:SetActiveEx(key == panelType)
        end
    end
    local childPanelType = XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE
    self.BtnReady.gameObject:SetActiveEx(panelType == childPanelType.MAIN)
    self.BtnChange.gameObject:SetActiveEx(panelType == childPanelType.ROLE)
    self.BtnSelected.gameObject:SetActiveEx(panelType == childPanelType.ROLE)
    -- 加载子面板
    local childPanelData = self.ChildPanelInfoDic[panelType]
    -- 加载panel asset
    local instanceGo = childPanelData.instanceGo
    if instanceGo == nil then
        instanceGo = childPanelData.uiParent:LoadPrefab(childPanelData.assetPath)
        childPanelData.instanceGo = instanceGo
    end
    -- 加载panel proxy
    local instanceProxy = childPanelData.instanceProxy
    if instanceProxy == nil then
        instanceProxy = childPanelData.proxy.New(instanceGo, self)
        childPanelData.instanceProxy = instanceProxy
    end
    -- 加载proxy参数
    local proxyArgs = {}
    if childPanelData.proxyArgs then
        for _, argName in ipairs(childPanelData.proxyArgs) do
            if type(argName) == "string" then
                proxyArgs[#proxyArgs + 1] = self[argName]
            else
                proxyArgs[#proxyArgs + 1] = argName
            end
        end
    end
    instanceProxy:SetData(table.unpack(proxyArgs))
    if panelType == childPanelType.ROLE then
        self.LastSelectableRole = self.CurrentRole
        self:SetIsSelected(true)
    end
    if panelType == childPanelType.MAIN then
        if self.CurrentRole:GetIsLock() then
            self:UpdateCurrentRole(self.LastSelectableRole)
        end
    end
end
--endregion

--region Ui - PanelRole
function XUiSameColorGameBoss:InitSelectRole()
    local lastRoleId = self.CurrentBoss:GetLastRoleId()
    if lastRoleId ~= nil and lastRoleId > 0 then
        self.CurrentRole = self.RoleManager:GetRole(lastRoleId)
        if self.CurrentRole:GetIsLock() then -- 锁住的换回默认第一个
            self.CurrentRole = self.RoleManager:GetRoles()[1]
        end
    else
        self.CurrentRole = self.RoleManager:GetRoles()[1]
    end
end

function XUiSameColorGameBoss:SetIsSelected(value)
    self.BtnChange.gameObject:SetActiveEx(not value)
    self.BtnSelected.gameObject:SetActiveEx(value)
    self.BtnSelected:SetDisable(true)
end

function XUiSameColorGameBoss:GetLastSelectableRole()
    return self.LastSelectableRole
end
--endregion

--region Ui - Tip
function XUiSameColorGameBoss:CheckGetNewRoleTip()
     if self.SameColorGameManager.GetIsFirstOpenRoleObtainUi() then
         XLuaUiManager.Open("UiSameColorGameObtain", self.RoleManager:GetInitRoles())
     end
end
--endregion

--region Scene - Model
function XUiSameColorGameBoss:InitSceneModel(uiNearRootObj)
    ---@type XUiPanelRoleModel
    self.UiPanelRoleModel = XUiPanelRoleModel.New(uiNearRootObj:GetObject("PanelRoleModel"), self.Name, nil, true)
    ---@type XUiPanelRoleModel
    self.UiPanelBossModel = XUiPanelRoleModel.New(uiNearRootObj:GetObject("PanelBossModel"), self.Name, nil, true)
end

function XUiSameColorGameBoss:UpdateCurrentRole(role)
    if role == nil then return end
    self.CurrentRole = role
    self.CurrentBoss:SetLastRoleId(role:GetId())
    self:UpdateRoleModel(self.CurrentRole)
    self:UpdateReadyBtnStatus()
end

function XUiSameColorGameBoss:UpdateRoleModel(role)
    local characterModelName = role:GetModelId()
    if string.IsNilOrEmpty(characterModelName) then
        characterModelName = XMVCA.XCharacter:GetCharModel(role:GetCharacterViewModel():GetId())
    end
    self.UiPanelRoleModel:UpdateRoleModelWithAutoConfig(characterModelName, XModelManager.MODEL_UINAME.XUiSameColorGameBoss)
    self.UiPanelRoleModel:ShowRoleModel()
    
    self._Control:HandleModelReadyHideNode(self.UiPanelRoleModel:GetModelInfoByName(role:GetModelId()), role:GetBattleModelId())
end

function XUiSameColorGameBoss:UpdateBossModel(boss)
    self.UiPanelBossModel:UpdateRoleModelWithAutoConfig(boss:GetModelId(), XModelManager.MODEL_UINAME.XUiSameColorGameBoss)
    -- v1.31 隐藏模型部分节点
    self._Control:HandleModelReadyHideNode(self.UiPanelBossModel:GetModelInfoByName(boss:GetModelId()), boss:GetBattleModelId())
    self.UiPanelBossModel:ShowRoleModel()
end

---@param model XUiPanelRoleModel
function XUiSameColorGameBoss:SetModelActive(model, value)
    if not model then
        return
    end
    if value then
        model:ShowRoleModel()
    else
        model:HideRoleModel()
    end
end

function XUiSameColorGameBoss:Clear()
    self.UiPanelBossModel.Transform:DestroyChildren()
    self.UiPanelRoleModel.Transform:DestroyChildren()
    self:SetCameraType(0)
end
--endregion

--region Scene - Camera
function XUiSameColorGameBoss:InitSceneCamera(uiNearRootObj)
    local childPanelType = XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE
    -- 动画
    self.NearCameraAnimDic = {
        [childPanelType.BOSS] = {
            [childPanelType.MAIN] = uiNearRootObj:GetObject("NearCameraBossBack")
        },
        [childPanelType.ROLE] = {
            [childPanelType.MAIN] = uiNearRootObj:GetObject("NearCameraRoleBack"),
        },
        [childPanelType.READY] = {
            [childPanelType.MAIN] = uiNearRootObj:GetObject("NearCameraReadyBack"),
        },
        [childPanelType.MAIN] = {
            [childPanelType.BOSS] = uiNearRootObj:GetObject("NearCameraBossEnable"),
            [childPanelType.ROLE] = uiNearRootObj:GetObject("NearCameraRoleEnable"),
            [childPanelType.READY] = uiNearRootObj:GetObject("NearCameraRoleEnable2"),
        }
    }
    -- 角色摄像机
    self.NearCameraDic = {}
    for i = 0, 4 do
        self.NearCameraDic[i] = uiNearRootObj:GetObject("NearCamera" .. i)
    end
    self.CameraBrain = uiNearRootObj:GetObject("CameraBrain")
    -- 场景摄像机
    local uiFarRootObj = self.UiModel.UiFarRoot:GetComponent("UiObject")
    self.FarCameraDic = {}
    for i = 0, 4 do
        self.FarCameraDic[i] = uiFarRootObj:GetObject("FarCamera" .. i)
    end
end

function XUiSameColorGameBoss:SetCameraType(panelType, fromType)
    for i = 0, 4 do
        self.NearCameraDic[i].gameObject:SetActiveEx(i == panelType)
        self.FarCameraDic[i].gameObject:SetActiveEx(i == panelType)
    end
    if panelType == 0 then
        return
    end
    local animTime = 0
    -- 播放动画
    local anim = self.NearCameraAnimDic[fromType]
    if anim then
        anim = anim[panelType]
    end
    if anim then
        animTime = anim.duration
    end
    -- 显示角色模型
    local childPanelType = XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE
    local time = self.TransformDic[fromType][panelType] or 0
    local bossActive = panelType == childPanelType.MAIN or panelType == childPanelType.BOSS
    local roleActive = panelType == childPanelType.MAIN or panelType == childPanelType.ROLE or panelType == childPanelType.READY
    if time <= 0 then
    else
        time = math.max(animTime, time)
        XLuaUiManager.SetMask(true)
        XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.SetMask(false)
            self:SetModelActive(self.UiPanelBossModel, bossActive)
            self:SetModelActive(self.UiPanelRoleModel, roleActive)
        end, math.floor(time * 1000))
    end
    if anim then
        anim:Play()
    end
end
--endregion

--region Ui - BtnListener
function XUiSameColorGameBoss:AddBtnListener()
    self.BtnBack.CallBack = function() self:OnBtnBackClicked() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnReady.CallBack = function() self:OnBtnReadyClicked() end
    self.BtnChange.CallBack = function() self:OnBtnChangeClicked() end
    self.BtnShop.CallBack = function() self:OnBtnShopClicked() end
    self:BindHelpBtn(self.BtnHelp, self._Control:GetCfgHelpId())
end

function XUiSameColorGameBoss:OnBtnReadyClicked()
    if not self.CurrentRole:GetIsInUnlockTime() then
        XUiManager.TipError(XUiHelper.GetText("SCRoleTimeLockTips", self.CurrentRole:GetOpenTimeStr()))
        return
    end
    self:UpdateChildPanel(XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE.READY)
end

function XUiSameColorGameBoss:OnBtnChangeClicked()
    if self.CurrentRole == self.LastSelectableRole then
        return
    end
    self:UpdateChildPanel(XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE.MAIN)
end

function XUiSameColorGameBoss:OnBtnShopClicked()
    self._Control:OpenShop()
end

function XUiSameColorGameBoss:OnBtnBackClicked()
    if self.CurrentChildType == XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE.ROLE then
        self:UpdateCurrentRole(self:GetLastSelectableRole())
    end
    if self.CurrentChildType == XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE.MAIN then
        self:Close()
    else
        self:UpdateChildPanel(XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE.MAIN)
    end
end
--endregion

return XUiSameColorGameBoss