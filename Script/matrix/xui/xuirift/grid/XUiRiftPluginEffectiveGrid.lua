---@class XUiRiftPluginEffectiveGrid : XUiNode
---@field Parent XUiRiftChoosePlugin
---@field _Control XRiftControl
local XUiRiftPluginEffectiveGrid = XClass(XUiNode, "XUiRiftPluginEffectiveGrid")

function XUiRiftPluginEffectiveGrid:OnStart()

end

function XUiRiftPluginEffectiveGrid:Init(role, plugin, isDetailTxt, isBagShow)
    ---@type XBaseRole
    self._Role = role
    if not self._Grid then
        ---@type XUiRiftPluginGrid
        self._Grid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid").New(self.GridRiftCore, self.Parent)
    end
    self._IsBagShow = isBagShow
    self:Refresh(plugin, isDetailTxt)
end

---@param plugin XTableRiftPlugin
function XUiRiftPluginEffectiveGrid:Refresh(plugin, isDetailTxt)
    self._Plugin = plugin
    self._Grid:Refresh(plugin)
    self.TxtPluginName.text = plugin.Name
    self.TxtLoad.text = plugin.Load
    self.TxtPluginEffective.text = self._Control:GetPluginDesc(plugin.Id, isDetailTxt)
    local isWear = self._Control:CheckHasPlugin(self._Role, plugin.Id)
    self._Grid:SetIsWear(isWear) -- 只有总览才需要显示穿戴状态
    local fixTypeList = self._Control:GetPluginPropTag(plugin.Id)
    XUiHelper.RefreshCustomizedList(self.PanelAddition.parent, self.PanelAddition, #fixTypeList, function(i, go)
        local uiObject = {}
        XTool.InitUiObjectByUi(uiObject, go)
        uiObject.TxtAddition.text = fixTypeList[i]
    end)
    -- 随机属性
    ---@type UnityEngine.Playables.PlayableDirector[]
    self._AffixAnimations = {}
    XUiHelper.RefreshCustomizedList(self.GridAffix.parent, self.GridAffix, plugin.SlotCount, function(index, go)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        local affix = self._Control:GetPluginRandomAffixByIdx(self._Plugin.Id, index)
        if XTool.IsNumberValid(affix) then
            local cfg = self._Control:GetRandomAffixById(affix)
            uiObject.GridAffix:SetButtonState(CS.UiButtonState.Normal)
            uiObject.GridAffix:SetSprite(cfg.Icon)
            if self._Control:IsRandomAffixMaxLevel(self._Plugin.Id,index) then
                local color = self._Control:GetMaxLevelPluginAffixColor()
                uiObject.GridAffix:SetNameByGroup(0, string.format("<color=%s>+%s</color>", color, cfg.Desc[2]))
            else
                uiObject.GridAffix:SetNameByGroup(0, string.format("+%s", cfg.Desc[2]))
            end
        else
            uiObject.GridAffix:SetButtonState(CS.UiButtonState.Disable)
        end
        uiObject.GridAffix.CallBack = function()
            self:OnBtnRandomAffixClick(index)
        end
        self._AffixAnimations[index] = uiObject.GridAffixUnlockEnable
    end)
    self.TxtNoAffix.gameObject:SetActiveEx(plugin.SlotCount == 0)
end

function XUiRiftPluginEffectiveGrid:OnBtnRandomAffixClick(index)
    XLuaUiManager.Open("UiRiftPopupAffix", self._Plugin.Id, index, function(type, slot)
        self.Parent:PlayUnlockAffixTween(self._Plugin.Id, type, slot)
    end)
end

function XUiRiftPluginEffectiveGrid:PlayTween(pluginId, type, slot)
    if self._Plugin.Id ~= pluginId then
        return
    end
    if XTool.IsTableEmpty(self._AffixAnimations) then
        return
    end
    local SetMaskShowFunc = handler(self, self.SetMaskShow)
    local SetMaskHideFunc = handler(self, self.SetMaskHide)
    if type == 2 then
        for _, anim in pairs(self._AffixAnimations) do
            anim.transform:PlayTimelineAnimation(SetMaskHideFunc, SetMaskShowFunc)
        end
    else
        local anim = self._AffixAnimations[slot]
        if anim then
            anim.transform:PlayTimelineAnimation(SetMaskHideFunc, SetMaskShowFunc)
        end
    end
end

function XUiRiftPluginEffectiveGrid:SetMaskShow()
    XLuaUiManager.SetMask(true)
end

function XUiRiftPluginEffectiveGrid:SetMaskHide()
    XLuaUiManager.SetMask(false)
end

function XUiRiftPluginEffectiveGrid:SetSelected(bo)
    self.PanelSelect.gameObject:SetActiveEx(bo)
end

return XUiRiftPluginEffectiveGrid
