local XUiRuleDetail = XLuaUiManager.Register(XLuaUi, "UiLivWarmRaceLog")

function XUiRuleDetail:OnAwake()
    -- XRuleViewModel
    self.RuleViewModels = {}
    -- 子页面配置
    self.ChildPanelInfoDic = {
        [RuleViewType.Text] = {
            uiParent = self.PanelTextParent,
            proxy = require("XUi/XUiCommon/XUiRule/XUiRuleTextPanel"),
            instanceGo = self.PanelText,
        },
        [RuleViewType.DropItem] = {
            uiParent = self.PanelDropItemParent,
            proxy = require("XUi/XUiCommon/XUiRule/XUiRuleDropItemPanel"),
            instanceGo = self.PanelDropItem,
        },
    }
    self:RegisterUiEvents()
end

-- ruleViewModels : XRuleViewModel
function XUiRuleDetail:OnStart(ruleViewModels)
    self.RuleViewModels = ruleViewModels
    -- 创建左边按钮组
    self:CreateTabBtns()
end

--######################## 私有方法 ########################

function XUiRuleDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiRuleDetail:CreateTabBtns()
    self.BtnTabPrefab.gameObject:SetActiveEx(false)
    local go, button
    local buttons = {}
    for index, ruleViewModel in ipairs(self.RuleViewModels) do
        go = XUiHelper.Instantiate(self.BtnTabPrefab, self.PanelBtnTab.transform)
        button = go:GetComponent("XUiButton")
        button:SetNameByGroup(0, ruleViewModel:GetTitle())
        buttons[index] = button
        go.gameObject:SetActiveEx(true)
    end
    self.PanelBtnTab:Init(buttons, function(index)
        self:OnBtnTabClicked(index)
    end)
    self.PanelBtnTab:SelectIndex(1)
end

function XUiRuleDetail:OnBtnTabClicked(index)
    local ruleViewModel = self.RuleViewModels[index]
    self:UpdateChildPanel(ruleViewModel)
end

-- ruleViewModel : XRuleViewModel
function XUiRuleDetail:UpdateChildPanel(ruleViewModel)
    local ruleType = ruleViewModel:GetType()
    for key, data in pairs(self.ChildPanelInfoDic) do
        data.uiParent.gameObject:SetActiveEx(key == ruleType)
    end
    -- 加载子面板
    local childPanelData = self.ChildPanelInfoDic[ruleType]
    if not childPanelData then return end
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
    instanceProxy:SetData(ruleViewModel, table.unpack(proxyArgs))
end

return XUiRuleDetail