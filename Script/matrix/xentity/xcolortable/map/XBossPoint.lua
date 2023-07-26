local XBasePoint = require("XEntity/XColorTable/Map/XBasePoint")
local XBossPoint = XClass(XBasePoint, "XBossPoint")

function XBossPoint:Ctor()
    self:_Init()
end

-- overrride
-------------------------------------------------------------------

function XBossPoint:SetTipPanelActive(active)
    if active then
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_OPEN_MAPPOINT_TIP, self, self.Transform.position)
    else
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_CLOSE_MAPPOINT_TIP)
    end
end

-------------------------------------------------------------------



-- public
-------------------------------------------------------------------

function XBossPoint:RefreshBossLv(bossLevels)
    if self:GetType() ~= XColorTableConfigs.PointType.Boss then
        return
    end
    -- 根除
    self:_RefreshLv(bossLevels[self:GetColorType()])

    local changeValue = bossLevels[self:GetColorType()] - self._BossLv
    if changeValue == 0 then
        return
    end
    self._BossLv = bossLevels[self:GetColorType()]
    self.TxtLvUpDown.text = changeValue > 0 and "+" .. changeValue or changeValue
    self.TxtLvUpDown.transform.localPosition = self.LvUpDownInitPosition
    self:_PlayLvUpDownAnim()
end

function XBossPoint:SetData(bossLv)
    local bgIcon = XColorTableConfigs.GetBossPointBgIcon(self:GetColorType(), self:GetType() ~= XColorTableConfigs.PointType.Boss)
    if self.Bg.sprite then
        self.Bg:SetSprite(bgIcon)
    else
        self.Bg:SetRawImage(bgIcon)
    end
    self.PanelEffect.gameObject:SetActiveEx(self:GetType() == XColorTableConfigs.PointType.HideBoss)
    if self:GetType() == XColorTableConfigs.PointType.HideBoss then
        local bgMaskIcon = XColorTableConfigs.GetHideBossPointBgMaskIcon()
        self.ImgSelectIcon:SetSprite(XColorTableConfigs.GetBossPointSelectIcon(self:GetColorType(), self:GetType() ~= XColorTableConfigs.PointType.Boss))
        self.Bg2 = XUiHelper.TryGetComponent(self.Transform, "Bg2", "Image")
        if self.Bg2 and bgMaskIcon then
            self.Bg2:SetSprite(bgMaskIcon)
        end
    end

    self.Icon:SetRawImage(self:GetIcon())
    self.TxtName.text = self:GetName()

    if not bossLv then
        return
    end
    self._BossLv = bossLv
    self:_RefreshLv(self._BossLv)
    self.TxtLv.text = XUiHelper.GetText("ColorTableLvTxt", self._BossLv)
    self.LvUpDownInitPosition = self.TxtLvUpDown.transform.localPosition
end

function XBossPoint:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_BLOCKSETTLE, self.RefreshBossLv, self)
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_BOSSLEVELCHANGE, self.RefreshBossLv, self)
end

function XBossPoint:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_BLOCKSETTLE, self.RefreshBossLv, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_BOSSLEVELCHANGE, self.RefreshBossLv, self)
end

-------------------------------------------------------------------


-- private
-------------------------------------------------------------------

function XBossPoint:_Init()
    self.TxtLvUpDown.gameObject:SetActiveEx(false)
    self.PanelKill.gameObject:SetActiveEx(false)
    self.TxtLv.gameObject:SetActiveEx(false)
end

function XBossPoint:_RefreshLv(bossLv)
    self.PanelKill.gameObject:SetActiveEx(bossLv == 0)
    self.TxtLv.gameObject:SetActiveEx(bossLv > 0)
    self.TxtLv.text = XUiHelper.GetText("ColorTableLvTxt", bossLv)
end

function XBossPoint:_PlayLvUpDownAnim()
    self.TxtLvUpDown.gameObject:SetActiveEx(true)
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.TxtLvUpDown.gameObject:SetActive(false)
    end, 2000)
end

-------------------------------------------------------------------

return XBossPoint