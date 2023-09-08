local XUiPanelItemChange = require("XUi/XUiBiancaTheatre/Common/XUiPanelItemChange")

--######################## XUiComfirmPanel ########################
local XUiComfirmPanel = XClass(nil, "XUiComfirmPanel")

function XUiComfirmPanel:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiComfirmPanel:SetData(desc, comfirmText, callback)
    self.GameObject:SetActiveEx(true)
    self.TxtContent.text = desc
    self.BtnOK:SetNameByGroup(0, comfirmText)
    XUiHelper.RegisterClickEvent(self, self.BtnOK, function()
        if callback then callback() end
    end)
end

--######################## XUiBiancaTheatreOutpost ########################
local XUiBiancaTheatreOutpost = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreOutpost")

function XUiBiancaTheatreOutpost:OnAwake()
    self.TheatreManager = XDataCenter.BiancaTheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
    -- 子页面配置
    self.ChildPanelInfoDic = {
        [XBiancaTheatreConfigs.NodeType.Event] = {
            [XBiancaTheatreConfigs.EventNodeType.Talk] = {
                uiParent = self.PanelComfirm,
                proxy = require("XUi/XUiBiancaTheatre/XUiComfirmEventNodePanel"),
                instanceGo = self.PanelComfirm,
            },
            [XBiancaTheatreConfigs.EventNodeType.Battle] = {
                uiParent = self.PanelComfirm,
                proxy = require("XUi/XUiBiancaTheatre/XUiComfirmEventNodePanel"),
                instanceGo = self.PanelComfirm,
            },
            [XBiancaTheatreConfigs.EventNodeType.Movie] = {
                uiParent = self.PanelComfirm,
                proxy = require("XUi/XUiBiancaTheatre/XUiComfirmEventNodePanel"),
                instanceGo = self.PanelComfirm,
            },
            [XBiancaTheatreConfigs.EventNodeType.Selectable] = {
                uiParent = self.PanelOption,
                proxy = require("XUi/XUiBiancaTheatre/XUiSelectableEventNodePanel"),
                instanceGo = self.PanelOption,
            },
            [XBiancaTheatreConfigs.EventNodeType.LocalReward] = {
                uiParent = self.PanelReward,
                proxy = require("XUi/XUiBiancaTheatre/XUiRewardEventNodePanel"),
                instanceGo = self.PanelReward,
            },
            [XBiancaTheatreConfigs.EventNodeType.GlobalReward] = {
                uiParent = self.PanelReward,
                proxy = require("XUi/XUiBiancaTheatre/XUiRewardEventNodePanel"),
                instanceGo = self.PanelReward,
            },
        },
        [XBiancaTheatreConfigs.NodeType.Shop] = {
            uiParent = self.PanelShop,
            proxy = require("XUi/XUiBiancaTheatre/XUiShopNodePanel"),
            instanceGo = self.PanelShop,
        },
    }
    self.Effect = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/Effect")
    self.Effect.gameObject:SetActiveEx(false)
    -- XUiComfirmPanel
    self.UiComfirmPanel = nil
    self:RefreshItemChange()
    self:RegisterUiEvents()

    XUiHelper.NewPanelActivityAssetSafe(self.TheatreManager.GetAdventureAssetItemIds(), self.PanelSpecialTool, self, nil, XDataCenter.BiancaTheatreManager.AdventureAssetItemOnBtnClick)
end

function XUiBiancaTheatreOutpost:OnStart()
    XDataCenter.BiancaTheatreManager.CheckBgmPlay()
    self:RefreshCurrentNode()
    if self.AnimStartAuto then self.AnimStartAuto:Play() end
end

function XUiBiancaTheatreOutpost:RefreshCurrentNode()
    self:RefreshNode(self.AdventureManager:GetCurrentChapter():GetCurrentNode())
    self.AdventureManager:ShowNextOperation()
end

function XUiBiancaTheatreOutpost:RefreshNode(node)
    if node == nil or XTool.UObjIsNil(self.GameObject) then
        return
    end
    if node:GetIsTriggerWithDirect() then
        node:RequestTriggerNode(function()
            if XLuaUiManager.IsUiShow("UiBiancaTheatreOutpost") then -- hack
                self:RefreshCurrentNode()
            end
        end)
        return
    end
    -- 标题
    self.TxtTitle.text = node.GetTitle and node:GetTitle()
    -- 标题内容
    self.TxtTitleContent.text = node:GetTitleContent()
    -- 显示的角色
    local roleIcon = node:GetRoleIcon()
    self.RImgRole.gameObject:SetActiveEx(roleIcon ~= nil)
    if roleIcon then
        self.RImgRole:SetRawImage(roleIcon)
    end
    -- 角色名称
    self.TxtRoleName.text = node:GetRoleName()
    -- 显示的角色说话内容
    self.TxtRoleContent.text = XUiHelper.ConvertLineBreakSymbol(node:GetRoleContent())
    -- 更新对应节点的Panel
    self:UpdateChildPanel(node)
    -- 更新灵视特效
    self:UpdateVisionEffect()
    if self.AnimSwitch then
        self.AnimSwitch:Play()
    end
    local bgAsset = node:GetBgAsset()
    if bgAsset then
        self.RImgBg:SetRawImage(bgAsset)
    end
end

function XUiBiancaTheatreOutpost:RefreshItemChange()
    local panelEnergyChangeList = {
        self.PanelEnergyChange2,
        self.PanelEnergyChange,
    }
    for index, itemId in ipairs(XDataCenter.BiancaTheatreManager.GetAdventureAssetItemIds()) do
        if panelEnergyChangeList[index] then
            self["ItemChange" .. index] = XUiPanelItemChange.New(panelEnergyChangeList[index], itemId)
        end
    end
end

function XUiBiancaTheatreOutpost:SetCloseFunc(closeFunc)
    self.CloseFunc = closeFunc
end

--######################## 私有方法 ########################

function XUiBiancaTheatreOutpost:RegisterUiEvents()
    self.BtnMainUi.CallBack = function() self:RunMain() end
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
end

function XUiBiancaTheatreOutpost:RunMain()
    XDataCenter.BiancaTheatreManager.SetIsAutoOpen(false)
    if self.CloseFunc then
        self.CloseFunc()
    end
    XDataCenter.BiancaTheatreManager.RunMain()
end

function XUiBiancaTheatreOutpost:Close()
    if self.CloseFunc then
        --执行方法让外部关闭本界面
        self.CloseFunc()
        return
    end
    if not XLuaUiManager.IsUiLoad("UiBiancaTheatrePlayMain") then
        XLuaUiManager.PopThenOpen("UiBiancaTheatrePlayMain")
        return
    end
    self.Super.Close(self)
end

function XUiBiancaTheatreOutpost:UpdateVisionEffect()
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local visionValue = adventureManager:GetVisionValue() or 0
    local visionId = XBiancaTheatreConfigs.GetVisionIdByValue(visionValue)
    local isVisionOpen = XDataCenter.BiancaTheatreManager.CheckVisionIsOpen()
    if self.Effect then
        self.Effect.gameObject:LoadUiEffect(XBiancaTheatreConfigs.GetVisionUiEffectUrl(visionId))
        self.Effect.gameObject:SetActiveEx(isVisionOpen)
    end
end

-- node : XANode
function XUiBiancaTheatreOutpost:UpdateChildPanel(node)
    -- 隐藏无关的面板，显示对应的面板
    self:HideAllChildPanel()
    -- 获取面板数据
    local nodeType = node:GetNodeType()
    local childPanelData = nil
    if nodeType == XBiancaTheatreConfigs.NodeType.Event then
        childPanelData = self.ChildPanelInfoDic[nodeType][node:GetEventType()]
    else
        childPanelData = self.ChildPanelInfoDic[nodeType]
    end

    if not childPanelData then return end
    childPanelData.uiParent.gameObject:SetActiveEx(true)
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
    local proxyArgs = { node }
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
end

function XUiBiancaTheatreOutpost:SwitchComfirmPanel(desc, comfirmText, callback)
    self:HideAllChildPanel()
    if self.UiComfirmPanel == nil then
        self.UiComfirmPanel = XUiComfirmPanel.New(self.PanelComfirm)
    end
    self.UiComfirmPanel:SetData(desc, comfirmText, callback)
end

function XUiBiancaTheatreOutpost:HideAllChildPanel()
    for key, data in pairs(self.ChildPanelInfoDic) do
        if key == XBiancaTheatreConfigs.NodeType.Event then
            for eventNodeType, eventData in pairs(data) do
                eventData.uiParent.gameObject:SetActiveEx(false)
            end
        else
            data.uiParent.gameObject:SetActiveEx(false)
        end
    end
    self.PanelTitle.gameObject:SetActiveEx(false)
end

function XUiBiancaTheatreOutpost:ShowPanelTitle(title, content)
    self.TxtTitle.text = title
    self.TxtTitleContent.text = content
    self.PanelTitle.gameObject:SetActiveEx(true)
end

return XUiBiancaTheatreOutpost