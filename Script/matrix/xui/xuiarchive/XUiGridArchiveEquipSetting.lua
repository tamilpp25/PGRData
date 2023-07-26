--
-- Author: wujie
-- Note: 图鉴装备和意识的设定/故事格子

local XUiGridArchiveEquipSetting = XClass(nil, "XUiGridArchiveEquipSetting")

local stringFind = string.find
local stringGsub = string.gsub

function XUiGridArchiveEquipSetting:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridArchiveEquipSetting:Refresh(subSystemType, settingData)
    local settingId = settingData.Id
    local isOpen = false
    if subSystemType == XArchiveConfigs.SubSystemType.Weapon then
        isOpen = XDataCenter.ArchiveManager.IsWeaponSettingOpen(settingId)
    elseif subSystemType == XArchiveConfigs.SubSystemType.Awareness then
        isOpen = XDataCenter.ArchiveManager.IsAwarenessSettingOpen(settingId)
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