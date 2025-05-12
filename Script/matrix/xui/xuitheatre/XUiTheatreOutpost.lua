--######################## XUiComfirmPanel ########################
local XUiComfirmPanel = XClass(nil, "XUiComfirmPanel")

function XUiComfirmPanel:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiComfirmPanel:SetData(desc, comfirmText, callback)
    self.GameObject:SetActiveEx(true)
    self.TxtContent.text = desc
    self.BtnConfirm:SetNameByGroup(0, comfirmText)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, function()
        if callback then callback() end
    end)
end

--######################## XUiTheatreOutpost ########################
local XUiTheatreOutpost = XLuaUiManager.Register(XLuaUi, "UiTheatreOutpost")

function XUiTheatreOutpost:OnAwake()
    self.TheatreManager = XDataCenter.TheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
    -- 子页面配置
    self.ChildPanelInfoDic = {
        [XTheatreConfigs.NodeType.Event] = {
            [XTheatreConfigs.EventNodeType.Talk] = {
                uiParent = self.PanelComfirm,
                proxy = require("XUi/XUiTheatre/XUiComfirmEventNodePanel"),
                instanceGo = self.PanelComfirm,
            },
            [XTheatreConfigs.EventNodeType.Battle] = {
                uiParent = self.PanelComfirm,
                proxy = require("XUi/XUiTheatre/XUiComfirmEventNodePanel"),
                instanceGo = self.PanelComfirm,
            },
            [XTheatreConfigs.EventNodeType.Movie] = {
                uiParent = self.PanelComfirm,
                proxy = require("XUi/XUiTheatre/XUiComfirmEventNodePanel"),
                instanceGo = self.PanelComfirm,
            },
            [XTheatreConfigs.EventNodeType.Selectable] = {
                uiParent = self.PanelOption,
                proxy = require("XUi/XUiTheatre/XUiSelectableEventNodePanel"),
                instanceGo = self.PanelOption,
            },
            [XTheatreConfigs.EventNodeType.LocalReward] = {
                uiParent = self.PanelReward,
                proxy = require("XUi/XUiTheatre/XUiRewardEventNodePanel"),
                instanceGo = self.PanelReward,
            },
            [XTheatreConfigs.EventNodeType.GlobalReward] = {
                uiParent = self.PanelReward,
                proxy = require("XUi/XUiTheatre/XUiRewardEventNodePanel"),
                instanceGo = self.PanelReward,
            },
        },
        [XTheatreConfigs.NodeType.Shop] = {
            uiParent = self.PanelShop,
            proxy = require("XUi/XUiTheatre/XUiShopNodePanel"),
            instanceGo = self.PanelShop,
        },
    }
    -- XUiComfirmPanel
    self.UiComfirmPanel = nil
    self:RegisterUiEvents()
end

function XUiTheatreOutpost:OnStart()
    self:RefreshCurrentNode()
    if self.AnimStartAuto then self.AnimStartAuto:Play() end
end

function XUiTheatreOutpost:RefreshCurrentNode()
    self:RefreshNode(self.AdventureManager:GetCurrentChapter():GetCurrentNode())
    self.AdventureManager:ShowNextOperation()
end

function XUiTheatreOutpost:RefreshNode(node)
    if node == nil then
        RunAsyn(function()
            if XLuaUiManager.IsUiPushing("UiObtain") then
                local signalCode = XLuaUiManager.AwaitSignal("UiObtain", "Close", self)
                if signalCode ~= XSignalCode.SUCCESS then return end
                self:Remove()
            else
                self:Close()
            end
        end)
        return
    end
    if node:GetIsTriggerWithDirect() then
        node:RequestTriggerNode(function()
            if XLuaUiManager.IsUiShow("UiTheatreOutpost") then -- hack
                self:RefreshCurrentNode()
            end
        end)
        return
    end
    -- 标题
    self.TxtTitle.text = node:GetTitle()
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
    if self.AnimSwitch then
        self.AnimSwitch:Play()
    end
    local bgAsset = node:GetBgAsset()
    if bgAsset then
        self.RImgBg:SetRawImage(bgAsset)
    end
end

--######################## 私有方法 ########################

function XUiTheatreOutpost:RegisterUiEvents()
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
end

-- node : XANode
function XUiTheatreOutpost:UpdateChildPanel(node)
    -- 隐藏无关的面板，显示对应的面板
    self:HideAllChildPanel()
    -- 获取面板数据
    local nodeType = node:GetNodeType()
    local childPanelData = nil
    if nodeType == XTheatreConfigs.NodeType.Event then
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

function XUiTheatreOutpost:SwitchComfirmPanel(desc, comfirmText, callback)
    self:HideAllChildPanel()
    if self.UiComfirmPanel == nil then
        self.UiComfirmPanel = XUiComfirmPanel.New(self.PanelComfirm)
    end
    self.UiComfirmPanel:SetData(desc, comfirmText, callback)
end

function XUiTheatreOutpost:HideAllChildPanel()
    for key, data in pairs(self.ChildPanelInfoDic) do
        if key == XTheatreConfigs.NodeType.Event then
            for eventNodeType, eventData in pairs(data) do
                eventData.uiParent.gameObject:SetActiveEx(false)
            end
        else
            data.uiParent.gameObject:SetActiveEx(false)
        end
    end    
end

return XUiTheatreOutpost