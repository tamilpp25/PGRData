local XUiGridKillZonePluginDesc = XClass(nil, "XUiGridKillZonePluginDesc")

function XUiGridKillZonePluginDesc:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridKillZonePluginDesc:Refresh(desc, level, currentLevel)
    local isCurrent = level == currentLevel

    if isCurrent then
        self.TxtLevelCur.text = CsXTextManagerGetText("KillZonePlguinMaxLevelSuffix", level)
        self.TxtSkillDesCur.text = desc

    else
        self.TxtLevel.text = CsXTextManagerGetText("KillZonePlguinMaxLevelSuffix", level)
        self.TxtSkillDes.text = desc
    end

    self.TxtLevel.gameObject:SetActiveEx(not isCurrent)
    self.TxtSkillDes.gameObject:SetActiveEx(not isCurrent)
    self.TxtLevelCur.gameObject:SetActiveEx(isCurrent)
    self.TxtSkillDesCur.gameObject:SetActiveEx(isCurrent)
end

return XUiGridKillZonePluginDesc