
local XUiSSBRewardTabs = XClass(nil, "XUiSSBRewardTabs")

function XUiSSBRewardTabs:Ctor(tabGroup, btnTemplate, onSelectTabCb)
    self.TabGroup = tabGroup
    self.OnSelectCb = onSelectTabCb
    self:InitPanel(btnTemplate)
end

function XUiSSBRewardTabs:InitPanel(btnTemplate)
    local allModes = XDataCenter.SuperSmashBrosManager.GetModeSortByPriority()
    self.Index2ModeIdDic = {}
    local btns = {}
    local index = 1
    for priority, mode in pairs(allModes or {}) do
        local rewards = mode:GetAllRewardCfgs()
        if rewards and next(rewards) then
            local prefab = CS.UnityEngine.Object.Instantiate(btnTemplate.transform, self.TabGroup.transform)
            local button = prefab:GetComponent("XUiButton")
            if button then
                button:SetName(mode:GetName())
                table.insert(btns, button)
                self.Index2ModeIdDic[index] = mode:GetId()
                index = index + 1
            end
        end
    end
    self.TabGroup:Init(btns, function(index) self:SelectIndex(index) end)
    btnTemplate.gameObject:SetActiveEx(false)
    self.MaxIndex = #btns
end

function XUiSSBRewardTabs:SelectTab(index)
    self.TabGroup:SelectIndex(index <= self.MaxIndex and index or 1)
end

function XUiSSBRewardTabs:SelectIndex(index)
    if self.OnSelectCb then
        self.OnSelectCb(self.Index2ModeIdDic[index])
    end
end

return XUiSSBRewardTabs