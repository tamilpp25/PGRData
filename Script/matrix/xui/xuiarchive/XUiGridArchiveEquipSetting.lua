--
-- Author: wujie
-- Note: 图鉴装备和意识的设定/故事格子

local XUiGridArchiveEquipSetting = XClass(XUiNode, "XUiGridArchiveEquipSetting")

local stringFind = string.find
local stringGsub = string.gsub


function XUiGridArchiveEquipSetting:Refresh(subSystemType, settingData)
    local settingId = settingData.Id
    local isOpen = false
    if subSystemType == XEnumConst.Archive.SubSystemType.Weapon then
        isOpen = self._Control:IsWeaponSettingOpen(settingId)
    elseif subSystemType == XEnumConst.Archive.SubSystemType.Awareness then
        isOpen = self._Control:IsAwarenessSettingOpen(settingId)
    end

    if isOpen then
        self.PanelUnlock.gameObject:SetActiveEx(true)
        self.PanelLock.gameObject:SetActiveEx(false)
        self.TxtSettingTitle.text = settingData.Title

        local handledStr = settingData.Text
        local matchedStr = "\\n"
        local replacedStr = "\n"
        if stringFind(handledStr, matchedStr) then
            self.TxtSettingContent.text = stringGsub(handledStr, matchedStr, replacedStr)
        else
            self.TxtSettingContent.text = handledStr
        end
    else
        self.PanelUnlock.gameObject:SetActiveEx(false)
        self.PanelLock.gameObject:SetActiveEx(true)
        local conditionId = settingData.Condition
        local conditionTemplate = XConditionManager.GetConditionTemplate(conditionId)
        local conditionDesc = conditionTemplate.Desc
        self.TxtLockContent.text = conditionDesc
    end
end

return XUiGridArchiveEquipSetting