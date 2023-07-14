local XUiSameColorGamePanelBoss = require("XUi/XUiSameColorGame/XUiSameColorGamePanelBoss")
local XUiSameColorGamePanelRole = require("XUi/XUiSameColorGame/XUiSameColorGamePanelRole")
local XUiSameColorGamePanelReady = require("XUi/XUiSameColorGame/XUiSameColorGamePanelReady")
local XUiSameColorGamePanelMain = require("XUi/XUiSameColorGame/XUiSameColorGamePanelMain")
local XUiSameColorGameBoss = XLuaUiManager.Register(XLuaUi, "UiSameColorGameBoss")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

function XUiSameColorGameBoss:OnAwake()
    self.SameColorGameManager = XDataCenter.SameColorActivityManager
    self.RoleManager = self.SameColorGameManager.GetRoleManager()
    -- XSCBoss
    self.CurrentBoss = nil
    -- XSCRole
    self.LastSelectableRole = nil
    -- XSCRole
    self.CurrentRole = nil
    -- 模型
    local uiModel, uiModelGo, uiSceneInfo = self.SameColorGameManager.GetMainUiModelInfo()
    self.UiModel = uiModel
    uiModelGo.gameObject:SetActiveEx(true)
    uiSceneInfo.GameObject:SetActiveEx(false)
    uiSceneInfo.GameObject:SetActiveEx(true)
    local uiNearRootObj = self.UiModel.UiNearRoot:GetComponent("UiObject")
    self.UiPanelRoleModel = XUiPanelRoleModel.New(uiNearRootObj:GetObject("PanelRoleModel"), self.Name)
    self.UiPanelBossModel = XUiPanelRoleModel.New(uiNearRootObj:GetObject("PanelBossModel"), self.Name)
    local childPanelType = XSameColorGameConfigs.UiBossChildPanelType
    -- 动画
    self.NearCameraAnimDic = {
        [childPanelType.Boss] = {
            [childPanelType.Main] = uiNearRootObj:GetObject("NearCameraBossBack")
        },
        [childPanelType.Role] = {
            [childPanelType.Main] = uiNearRootObj:GetObject("NearCameraRoleBack"),
        },
        [childPanelType.Ready] = {
            [childPanelType.Main] = uiNearRootObj:GetObject("NearCameraReadyBack"),
        },
        [childPanelType.Main] = {
            [childPanelType.Boss] = uiNearRootObj:GetObject("NearCameraBossEnable"),
            [childPanelType.Role] = uiNearRootObj:GetObject("NearCameraRoleEnable"), 
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
    -- 页面显示数据
    local transformDic = {}
    for i = 1, 4 do
        transformDic[i] = {}
    end
    local mainCameraTime = XCameraHelper.GetBlendTime(self.CameraBrain, childPanelType.Main - 1)
    transformDic[childPanelType.Boss][childPanelType.Main] = mainCameraTime - 0.1
    transformDic[childPanelType.Role][childPanelType.Main] = mainCameraTime - 0.3
    -- transformDic[childPanelType.Ready][childPanelType.Main] = mainCameraTime - 0.3
    self.TransformDic = transformDic
    -- 子页面配置
    self.ChildPanelInfoDic = {
        [XSameColorGameConfigs.UiBossChildPanelType.Main] = {
            uiParent = self.PanelMain,
            proxy = XUiSameColorGamePanelMain,
            assetPath = XUiConfigs.GetComponentUrl("UiSameColorPanelMain"),
            proxyArgs = { "CurrentBoss", "CurrentRole" }
        },
        [XSameColorGameConfigs.UiBossChildPanelType.Role] = {
            uiParent = self.PanelRole,
            proxy = XUiSameColorGamePanelRole,
            assetPath = XUiConfigs.GetComponentUrl("UiSameColorPanelRole"),
            proxyArgs = { "CurrentRole", "CurrentBoss" }
        },
        [XSameColorGameConfigs.UiBossChildPanelType.Boss] = {
            uiParent = self.PanelBoss,
            proxy = XUiSameColorGamePanelBoss,
            assetPath = XUiConfigs.GetComponentUrl("UiSameColorPanelBoss"),
            proxyArgs = { "CurrentBoss" }
        },
        [XSameColorGameConfigs.UiBossChildPanelType.Ready] = {
            uiParent = self.PanelReady,
            proxy = XUiSameColorGamePanelReady,
            assetPath = XUiConfigs.GetComponentUrl("UiSameColorPanelReady"),
            proxyArgs = { "CurrentRole", "CurrentBoss" }
        },
    }
    -- 当前页面状态
    self.CurrentChildType = XSameColorGameConfigs.UiBossChildPanelType.Main
    -- 资源栏
    XUiHelper.NewPanelActivityAsset(self.SameColorGameManager.GetAssetItemIds(), self.PanelAsset)
    self:RegisterUiEvents()
end

function XUiSameColorGameBoss:OnStart(boss)
    self.CurrentBoss = boss
    local lastRoleId = boss:GetLastRoleId()
    if lastRoleId ~= nil and lastRoleId > 0 then
        self.CurrentRole = self.RoleManager:GetRole(lastRoleId)
        if self.CurrentRole:GetIsLock() then -- 锁住的换回默认第一个
            self.CurrentRole = self.RoleManager:GetRoles()[1]
        end
    else
        self.CurrentRole = self.RoleManager:GetRoles()[1]
    end
    self:UpdateBossModel(self.CurrentBoss)
    self:UpdateRoleModel(self.CurrentRole)
    -- 检查是否打开初始角色获取界面
    if self.SameColorGameManager.GetIsFirstOpenRoleObtainUi() then
        XLuaUiManager.Open("UiSameColorGameObtain", self.RoleManager:GetInitRoles())
    end
    local endTime = self.SameColorGameManager.GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self.SameColorGameManager.HandleActivityEndTime()
        end
    end)
end

function XUiSameColorGameBoss:OnEnable()
    XUiSameColorGameBoss.Super.OnEnable(self)
    if self.CurrentChildType == XSameColorGameConfigs.UiBossChildPanelType.Role then
        local lastRoleId = self.LastSelectableRole:GetId()
        self:UpdateChildPanel(self.CurrentChildType)
        self.LastSelectableRole = self.RoleManager:GetRole(lastRoleId)
        self:SetIsSelected(lastRoleId == self.CurrentRole:GetId())
        -- self:UpdateReadyBtnStatus()
    else
        self:UpdateChildPanel(self.CurrentChildType)
        self:UpdateReadyBtnStatus()
    end
end

function XUiSameColorGameBoss:OnDestroy()
    self:Clear()
    XUiSameColorGameBoss.Super.OnDestroy(self)
end

function XUiSameColorGameBoss:UpdateCurrentRole(role)
    if role == nil then return end
    self.CurrentRole = role
    self.CurrentBoss:SetLastRoleId(role:GetId())
    self:UpdateRoleModel(self.CurrentRole)
    self:UpdateReadyBtnStatus()
end

function XUiSameColorGameBoss:SetBtnReadyNormalText(value)
    self.BtnReady:SetNameByGroup(0, value)
    self:SetIsSelected(false)
end

function XUiSameColorGameBoss:SetIsSelected(value)
    self.BtnReady.gameObject:SetActiveEx(not value)
    self.BtnSelected.gameObject:SetActiveEx(value)
    self.BtnSelected:SetDisable(true)
end

function XUiSameColorGameBoss:GetLastSelectableRole()
    return self.LastSelectableRole
end

function XUiSameColorGameBoss:UpdateReadyBtnStatus()
    local isLock = self.CurrentRole:GetIsLock()
    self.BtnReady:SetButtonState(isLock and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiSameColorGameBoss:UpdateChildPanel(panelType)
    local fromChildType = self.CurrentChildType
    XScheduleManager.ScheduleOnce(function()
        self:SetCameraType(panelType, fromChildType)
    end, 1)
    self.CurrentChildType = panelType
    for key, data in pairs(self.ChildPanelInfoDic) do
        data.uiParent.gameObject:SetActiveEx(key == panelType)
    end
    local childPanelType = XSameColorGameConfigs.UiBossChildPanelType
    self.BtnReady.gameObject:SetActiveEx(panelType == childPanelType.Main or panelType == childPanelType.Role)
    self.BtnShop.gameObject:SetActiveEx(panelType ~= childPanelType.Ready and panelType ~= childPanelType.Boss)
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
    if panelType == childPanelType.Role then
        self.LastSelectableRole = self.CurrentRole
        self:SetIsSelected(true)
        -- self:SetBtnReadyNormalText(XUiHelper.GetText("SameColorGameReadyTip1"))
    end
    if panelType == childPanelType.Main then
        if self.CurrentRole:GetIsLock() then
            self:UpdateCurrentRole(self.LastSelectableRole)
        end
        self:SetBtnReadyNormalText(XUiHelper.GetText("SameColorGameReadyTip2"))
    end
end

--######################## 私有方法 ########################
function XUiSameColorGameBoss:RegisterUiEvents()
    self.BtnBack.CallBack = function() self:OnBtnBackClicked() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnReady.CallBack = function() self:OnBtnReadyClicked() end
    self.BtnShop.CallBack = function() self:OnBtnShopClicked() end
    self:BindHelpBtn(self.BtnHelp, self.SameColorGameManager.GetHelpId())
end

function XUiSameColorGameBoss:OnBtnReadyClicked()
    if not self.CurrentRole:GetIsInUnlockTime() then
        XUiManager.TipError(XUiHelper.GetText("SCRoleTimeLockTips", self.CurrentRole:GetOpenTimeStr()))
        return
    end
    if not self.CurrentRole:GetIsReceived() then
        XUiManager.TipError(XUiHelper.GetText("SCRoleReceivedTips"))
        return
    end
    if self.CurrentChildType == XSameColorGameConfigs.UiBossChildPanelType.Role then
        if self.CurrentRole == self.LastSelectableRole then
            return
        end
        self:UpdateChildPanel(XSameColorGameConfigs.UiBossChildPanelType.Main)
        return
    end
    self:UpdateChildPanel(XSameColorGameConfigs.UiBossChildPanelType.Ready)
end

function XUiSameColorGameBoss:OnBtnShopClicked()
    self.SameColorGameManager.OpenShopUi()
end

function XUiSameColorGameBoss:OnBtnBackClicked()
    if self.CurrentChildType == XSameColorGameConfigs.UiBossChildPanelType.Role then
        self:UpdateCurrentRole(self:GetLastSelectableRole())
    end
    if self.CurrentChildType == XSameColorGameConfigs.UiBossChildPanelType.Main then
        self:Close()
    else
        self:UpdateChildPanel(XSameColorGameConfigs.UiBossChildPanelType.Main)
    end
end

function XUiSameColorGameBoss:UpdateBossModel(boss)
    -- self.UiPanelBossModel:UpdateRoleModel(boss:GetModelId(), nil, XModelManager.MODEL_UINAME.XUiSameColorGameBoss
    --     , nil, true, false)
    self.UiPanelBossModel:UpdateRoleModelWithAutoConfig(boss:GetModelId(), XModelManager.MODEL_UINAME.XUiSameColorGameBoss)
    self.UiPanelBossModel:ShowRoleModel()
end

function XUiSameColorGameBoss:UpdateRoleModel(role)
    local characterModelName = role:GetModelId()
    if string.IsNilOrEmpty(characterModelName) then
        characterModelName = XDataCenter.CharacterManager.GetCharModel(role:GetCharacterViewModel():GetId())
    end
    -- self.UiPanelRoleModel:UpdateRoleModel(characterModelName, nil, XModelManager.MODEL_UINAME.XUiSameColorGameBoss
    --     , nil, true, true)
    self.UiPanelRoleModel:UpdateRoleModelWithAutoConfig(characterModelName, XModelManager.MODEL_UINAME.XUiSameColorGameBoss)
    self.UiPanelRoleModel:ShowRoleModel()
end

function XUiSameColorGameBoss:SetBossModelActive(value)
    if value then
        self.UiPanelBossModel:ShowRoleModel()
    else
        self.UiPanelBossModel:HideRoleModel()
    end
end

function XUiSameColorGameBoss:SetRoleModelActive(value)
    if value then
        self.UiPanelRoleModel:ShowRoleModel()
    else
        self.UiPanelRoleModel:HideRoleModel()
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
    local childPanelType = XSameColorGameConfigs.UiBossChildPanelType
    local time = self.TransformDic[fromType][panelType] or 0
    local bossActive = panelType == childPanelType.Main or panelType == childPanelType.Boss
    local roleActive = panelType == childPanelType.Main or panelType == childPanelType.Role or panelType == childPanelType.Ready
    if time <= 0 then
        self:SetBossModelActive(bossActive)
        self:SetRoleModelActive(roleActive)
    else
        time = math.max(animTime, time)
        XLuaUiManager.SetMask(true)
        XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.SetMask(false)
            self:SetBossModelActive(bossActive)
            self:SetRoleModelActive(roleActive)
        end, math.floor(time * 1000))
    end
    if anim then
        anim:Play()
    end
end

function XUiSameColorGameBoss:Clear()
    self.UiPanelBossModel.Transform:DestroyChildren()
    self.UiPanelRoleModel.Transform:DestroyChildren()
    self:SetCameraType(0)
end

return XUiSameColorGameBoss