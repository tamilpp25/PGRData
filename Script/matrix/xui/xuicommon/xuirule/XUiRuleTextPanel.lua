--######################## XUiTextItem ########################
local XUiTextItem = XClass(nil, "XUiTextItem")

function XUiTextItem:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiTextItem:SetData(title, desc)
    self.TxtRuleTittle.text = title
    self.TxtRule.text = desc
end

--######################## XUiRuleTextPanel ########################
local XUiRuleTextPanel = XClass(nil, "XUiRuleTextPanel")

function XUiRuleTextPanel:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    -- XRuleTextViewModel
    self.RuleTextViewModel = nil
end

-- ruleViewModel : XRuleTextViewModel
function XUiRuleTextPanel:SetData(ruleTextViewModel)
    self.RuleTextViewModel = ruleTextViewModel
    self.TxtTitle.text = ruleTextViewModel:GetTitle()
    self:RefreshItems()
end

function XUiRuleTextPanel:RefreshItems()
    if self.__initRefreshItems then return end
    local child
    local childCount = self.PanelContent.childCount
    -- 默认隐藏所有
    for i = 0, childCount - 1 do
        child = self.PanelContent:GetChild(i)
        child.gameObject:SetActiveEx(false)
    end
    local ruleDatas = self.RuleTextViewModel:GetRuleDatas()
    local ruleData, uiTextItem
    for i = 1, #ruleDatas do
        ruleData = ruleDatas[i]
        if i > childCount then -- 创建新的
            child = XUiHelper.Instantiate(self.TextItem, self.PanelContent)
        else
            child = self.PanelContent:GetChild(i - 1)
        end
        child.gameObject:SetActiveEx(true)
        uiTextItem = XUiTextItem.New(child)
        uiTextItem:SetData(ruleData.Title, ruleData.RuleDesc)
    end
    self.__initRefreshItems = true
end

return XUiRuleTextPanel