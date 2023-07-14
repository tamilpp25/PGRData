local XUiGrpluginIdAreaWarPlugin = XClass(nil, "XUiGrpluginIdAreaWarPlugin")

function XUiGrpluginIdAreaWarPlugin:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    local function clickFunc()
        clickCb(self.PluginId)
    end
    self.BtnDetail.CallBack = clickFunc
    self.BtnDetail2.CallBack = clickFunc
end

function XUiGrpluginIdAreaWarPlugin:Refresh(pluginId)
    self.PluginId = pluginId

    local unlockLevel = XAreaWarConfigs.GetPfLevelByPluginId(pluginId)
    local icon = XAreaWarConfigs.GetBuffIcon(pluginId)
    self.BtnDetail:SetNameByGroup(0, XAreaWarConfigs.GetBuffName(pluginId))

    local isUnlock = XDataCenter.AreaWarManager.IsPluginUnlock(pluginId) --已解锁
    local isUsing = XDataCenter.AreaWarManager.IsPluginUsing(pluginId) --装备中
    local canUnlock = XDataCenter.AreaWarManager.IsPluginCanUnlock(pluginId) --可解锁
    if isUnlock then
        --已解锁
        self.TxtLvUnlock.text = "Lv." .. unlockLevel
        self.ImgProgress.fillAmount = 1
        self.RImgBuffUnlock:SetRawImage(icon)
    else
        if canUnlock then
            --可解锁
            self.ImgProgress.fillAmount = 1
        else
            --不可解锁
            self.ImgProgress.fillAmount = 0
        end
        self.TxtLvLock.text = "Lv." .. unlockLevel
        self.RImgBuffLock:SetRawImage(icon)
    end

    self.ImgLvUnlock.gameObject:SetActiveEx(isUnlock)
    self.TxtLvUnlock.gameObject:SetActiveEx(isUnlock)
    self.ImgLvLock.gameObject:SetActiveEx(not isUnlock)
    self.TxtLvLock.gameObject:SetActiveEx(not isUnlock)
    self.ImgUnlock.gameObject:SetActiveEx(isUnlock)
    self.ImgBuffUnlock.gameObject:SetActiveEx(isUnlock)
    self.RImgBuffUnlock.gameObject:SetActiveEx(isUnlock)
    self.ImgBuffLock.gameObject:SetActiveEx(not isUnlock)
    self.RImgBuffLock.gameObject:SetActiveEx(not isUnlock)
    self.PaneCanUnlock.gameObject:SetActiveEx(canUnlock)
    self.TagEquip.gameObject:SetActiveEx(isUsing)
end

function XUiGrpluginIdAreaWarPlugin:PlayExpandAnim()
    if self.AnimPlayed then
        return
    end
    self.AnimPlayed = true
    self.GridBuffEnable:PlayTimelineAnimation()
end

--播放可装备插件动画
function XUiGrpluginIdAreaWarPlugin:PlayCanUseAnim()
    if not XDataCenter.AreaWarManager.IsPluginUnlock(self.PluginId) then
        return
    end
    self.SelectionTips:PlayTimelineAnimation()
end

return XUiGrpluginIdAreaWarPlugin
