---@class XUiPlanetBuildCardFilter
local XUiPlanetBuildCardFilter = XClass(nil, "XUiPlanetBuildCardFilter")

function XUiPlanetBuildCardFilter:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.OnValueChanged = nil
    self:InitDropDown()
    self:AddBtnClickListener()
end

--region 下拉列表
function XUiPlanetBuildCardFilter:InitDropDown()
    self.DropDown = self.GameObject:GetComponent("Dropdown")
    local Dropdown = CS.UnityEngine.UI.Dropdown
    local optionList = {}
    for _, talentCardFilter in pairs(XPlanetTalentConfigs.TalentCardFilter) do
        local option = Dropdown.OptionData()
        local name = XPlanetTalentConfigs.GetFilterName(talentCardFilter)
        option.text = name
        optionList[talentCardFilter] = option
    end
    for _, option in ipairs(optionList) do
        self.DropDown.options:Add(option)
    end
end

function XUiPlanetBuildCardFilter:RegisterOnValueChanged(cb)
    self.OnValueChanged = cb
end
--endregion


--region 交互绑定
function XUiPlanetBuildCardFilter:AddBtnClickListener()
    self.DropDown.onValueChanged:AddListener(function(value)
        -- DropDown是C#代码，value从0开始
        XDataCenter.PlanetManager.SetTalentBuildCardFilter(value + 1)
        if self.OnValueChanged then self.OnValueChanged() end
    end)
end

function XUiPlanetBuildCardFilter:OnBtnPandectClick()
    XLuaUiManager.Open("UiPlanetBuildView")
end
--endregion

return XUiPlanetBuildCardFilter