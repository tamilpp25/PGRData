--- 公会战7.0新增龙怒系统龙怒值显示
---@class XUiPanelDragonRage: XUiNode
---@field private _Control XGuildWarControl
local XUiPanelDragonRage = XClass(XUiNode, 'XUiPanelDragonRage')

function XUiPanelDragonRage:OnStart()
    self.BtnClose.gameObject:SetActiveEx(false)

    if self.BtnClose then
        self.BtnClose.CallBack = handler(self, self.OnDetailClose)
    end

    if self.BtnDetail then
        self.BtnDetail.CallBack = handler(self, self.OnDetailOpen)
    end
    
    self.TxtDetail.text = XGuildWarConfig.GetClientConfigValues('DragonRageLevelTips')[1]
end

function XUiPanelDragonRage:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_DRAGONRAGE_CHANGE, self.Refresh, self)
    self:OnDetailClose()
end

function XUiPanelDragonRage:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_DRAGONRAGE_CHANGE, self.Refresh, self)
end

function XUiPanelDragonRage:Refresh()
    -- 刷新进度条显示
    local uiProgressBar = nil
    local effect = nil
    local percent = 0

    self.ImgBarBlue.transform.parent.gameObject:SetActiveEx(false)
    self.ImgBarRed.transform.parent.gameObject:SetActiveEx(false)

    if self._Control.DragonRageControl:GetIsUnlockDragonRage() then
        if self._Control.DragonRageControl:GetIsDragonRageValueDown() then
            uiProgressBar = self.ImgBarRed
            effect = self.EffectRedRoot
        else
            uiProgressBar = self.ImgBarBlue
            effect = self.EffectBlueRoot
        end

        percent = self._Control.DragonRageControl:GetDragonRageValueMAX() == 0 and 0 or self._Control.DragonRageControl:GetDragonRageValue() / self._Control.DragonRageControl:GetDragonRageValueMAX()
        
        uiProgressBar.transform.parent.gameObject:SetActiveEx(true)
        uiProgressBar.fillAmount = percent
    end

    -- 刷新锁定状态显示
    self.ImgLock.gameObject:SetActiveEx(not self._Control.DragonRageControl:GetIsUnlockDragonRage())
    
    -- 显示龙怒等级描述
    self.TxtLv.text = 'Lv.'..tostring(self._Control.DragonRageControl:GetDragonRageLevel())
    
    -- 定位特效位置
    if effect then
        local showLimit = XGuildWarConfig.GetClientConfigValue('DragonRageEffectShowLowerLimit', 'Float', 1) or 0
        effect.gameObject:SetActiveEx(percent > showLimit)
        local width = effect.transform.parent.rect.width
        effect.transform.anchoredPosition = Vector2(width * percent, 0)
    end
end

function XUiPanelDragonRage:OnDetailOpen()
    self.BtnClose.gameObject:SetActiveEx(true)
    self.PanelDetail.gameObject:SetActiveEx(true)
end

function XUiPanelDragonRage:OnDetailClose()
    self.BtnClose.gameObject:SetActiveEx(false)
    self.PanelDetail.gameObject:SetActiveEx(false)
end

return XUiPanelDragonRage