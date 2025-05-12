local XUiGrpluginIdAreaWarPlugin = XClass(nil, "XUiGrpluginIdAreaWarPlugin")

function XUiGrpluginIdAreaWarPlugin:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    local function clickFunc()
        clickCb(self.PluginId)
    end
    
    self.GridBuff.CallBack=clickFunc
end

function XUiGrpluginIdAreaWarPlugin:Refresh(pluginId,isFirst,isLast)
    self.PluginId = pluginId
    
    --设置显示
    self.GridBuff:SetNameByGroup(0,XAreaWarConfigs.GetBuffName(self.PluginId))
    self.TxtTitleEn.gameObject:SetActiveEx(isFirst)

    isLast=isLast and true or false
    self.ImgProgress.transform.parent.gameObject:SetActiveEx(not isLast)
    
    --检查并设置解锁状态
    local unlockLevel = XAreaWarConfigs.GetPfLevelByPluginId(pluginId)
    local icon = XAreaWarConfigs.GetBuffIcon(pluginId)

    local isUnlock = XDataCenter.AreaWarManager.IsPluginUnlock(pluginId) --已解锁
    local canUnlock = XDataCenter.AreaWarManager.IsPluginCanUnlock(pluginId) --可解锁

    local unlockCount = XDataCenter.AreaWarManager.GetPluginUnlockCount() 
    
    if isUnlock then
        --已解锁
        --self.ImgProgress.fillAmount = 1
        self.RImgBuffUnlock:SetRawImage(icon)
    else
        --self.ImgProgress.fillAmount = 0
        
        self.RImgBuffLock:SetRawImage(icon)
    end
    self.ImgProgress.fillAmount = unlockCount > unlockLevel and 1 or 0
    --显示当前增幅对应的等级
    self.TxtLvLock.text = "Lv." .. unlockLevel
    --显示未激活的图标
    self.ImgUnlock.gameObject:SetActiveEx(unlockCount < unlockLevel)
    self.Panelununlocked.gameObject:SetActiveEx(not isUnlock)
    self.PanelUnlocked.gameObject:SetActiveEx(isUnlock)
    self.PanelLockable.gameObject:SetActiveEx(canUnlock)
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
