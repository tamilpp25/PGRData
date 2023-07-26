-- Grid - Boss
--===============================================================================
local XGridBoss  = XClass(nil, "XGridBoss")

function XGridBoss:Ctor(ui, color)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Color = color

    XTool.InitUiObject(self)
    self.Effect = self.Bg.transform:Find("Effect")
    self:SetSelect(false)
    self:SetEffect(false)
end

function XGridBoss:RefreshIcon(bossIcon)
    self.RImgIcon:SetRawImage(bossIcon)
end

function XGridBoss:RefreshLv(lv)
    self.TxtBoss2.text = lv
end

function XGridBoss:SetSelect(isSelect)
    self.Bg1.gameObject:SetActiveEx(isSelect)
    self.Bg2.gameObject:SetActiveEx(isSelect)
    self.Bg3.gameObject:SetActiveEx(isSelect)
end

function XGridBoss:SetActive(active)
    self.GameObject:SetActiveEx(active)
end

function XGridBoss:SetEffect(active)
    if not self.Effect then return end
    self.Effect.gameObject:SetActiveEx(false)
    if not active then
        return
    end
    self.Effect.gameObject:SetActiveEx(true)
end

function XGridBoss:GetColor()
    return self.Color
end

--===============================================================================



local XUiColorTableStageBoss = XLuaUiManager.Register(XLuaUi,"UiColorTableStageBoss")

function XUiColorTableStageBoss:OnAwake()
    self.GameManager = XDataCenter.ColorTableManager.GetGameManager()
    self.GameData = self.GameManager:GetGameData()

    self:_AddBtnListener()
end

function XUiColorTableStageBoss:OnStart(settleType, levelChanges, callback)
    self.CallBack = callback
    self.LevelChanges = levelChanges
    self.SettleType = settleType
    self.IsEpidemic = self.SettleType == XColorTableConfigs.TimelineType.Epidemic
    self:_InitUi()
    self:_Refresh()
end

function XUiColorTableStageBoss:OnEnable()
    if not self.IsEpidemic and not self.GameManager:GetDontShowRollBoss() and not self.GameData:CheckIsFirstGuideStage() then
        self:_PlayRollAnim()
    else
        self:_RefreshBoss(self.LevelChanges, true)
    end
end

-- private
----------------------------------------------------------------

function XUiColorTableStageBoss:_Refresh()
    local dontShowRollAnim = self.GameManager:GetDontShowRollBoss()
    if dontShowRollAnim then
        self.BtnGouxuan:SetButtonState(CS.UiButtonState.Select)
    end
    if self.SettleType == XColorTableConfigs.TimelineType.Normal then
        self.TextTitle.text = XUiHelper.GetText("ColorTableRollBossNormalTitle")
    elseif self.SettleType == XColorTableConfigs.TimelineType.Explode then
        self.TextTitle.text = XUiHelper.GetText("ColorTableRollBossExplodeTitle")
    elseif self.SettleType == XColorTableConfigs.TimelineType.Epidemic then
        self.TextTitle.text = XUiHelper.GetText("ColorTableRollBossEpidemicTitle")
    end
    self:_RefreshBoss(self.GameData:GetBossLevels())
end

function XUiColorTableStageBoss:_RefreshBoss(bossLevels, isShowSelect)
    local pointGroupId = XColorTableConfigs.GetMapPointGroupId(self.GameData:GetMapId())
    for _, bossObj in ipairs(self.ShowBoss) do
        local config =  XColorTableConfigs.GetPointConfig(pointGroupId, 0, bossObj:GetColor())
        if config then
            bossObj:RefreshIcon(config.Icon)
            bossObj:RefreshLv(bossLevels[bossObj:GetColor()])
        end
    end
    if self.GameData:CheckIsFirstGuideStage() then
        self.BtnGouxuan.gameObject:SetActiveEx(false)
        self.BossDir[XColorTableConfigs.ColorType.Red]:SetActive(false)
        self.BossDir[XColorTableConfigs.ColorType.Blue]:SetActive(false)
        self.BossDir[XColorTableConfigs.ColorType.Green].Transform.position = self.BossDir[XColorTableConfigs.ColorType.Blue].Transform.position
    end
    if isShowSelect then
        for color, value in ipairs(self.GameData:GetBossLevels()) do
            if self.BossDir[color] then
                self.BossDir[color]:SetEffect(value ~= self.LevelChanges[color])
                self.BossDir[color]:SetSelect(value ~= self.LevelChanges[color])
            end
        end
    end
end

function XUiColorTableStageBoss:_PlayRollAnim()
    XLuaUiManager.SetMask(true)
    -- 计算哪个Boss增长
    local targetColor
    local targetBoss
    for color, value in ipairs(self.GameData:GetBossLevels()) do
        if value ~= self.LevelChanges[color] then
            targetColor = color
        end
    end
    for index, obj in ipairs(self.ShowBoss) do
        if obj:GetColor() == targetColor then
            targetBoss = index
        end
    end
    local interval = 100
    local animFrame = 30
    local length = #self.ShowBoss

    if length <= 1 or not targetBoss or not targetColor then
        self:_RefreshBoss(self.LevelChanges, true)
        XLuaUiManager.SetMask(false)
        return
    end

    local count = 0
    local select = targetBoss + length - 1 > length and targetBoss - 1 or targetBoss + length - 1
    -- 匀渐变速
    local playFrame = 0
    local speedCounter = 0          -- 匀速帧的计数器
    local speedCountLimit = 5       -- 匀速帧的帧数
    local speedFrameCounter = 0     -- 当speedFrameCounter = speedFrameCountLimit时为速度变换帧
    local speedFrameCountLimit = 1  -- 控制speedFrameCountLimit形成变速效果
    XScheduleManager.Schedule(function()
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        playFrame = playFrame + 1
        speedFrameCounter = speedFrameCounter + 1
        if speedFrameCounter == speedFrameCountLimit then
            self:_AnimRefreshBossSelect(select)
            count = count + 1
            select = select + 1
            if select > length then
                select = 1
            end
            speedFrameCounter = 0
            speedCounter = speedCounter + 1
        end
        if speedCounter == speedCountLimit then
            speedCounter = 0
            speedCountLimit = speedCountLimit - 1
            speedFrameCountLimit = speedFrameCountLimit + 1
        end
        if playFrame == animFrame then
            self:_RefreshBoss(self.LevelChanges, true)
            XLuaUiManager.SetMask(false)
        end
    end, interval, animFrame, 0)
end

function XUiColorTableStageBoss:_AnimRefreshBossSelect(targetIndex)
    for index, bossObj in ipairs(self.ShowBoss) do
        bossObj:SetSelect(index == targetIndex)
    end
end

function XUiColorTableStageBoss:_InitUi()
    self.ShowBoss = {}
    self.BossDir = {}
    -- 未被根除的则添加进入Boss队列，key为Color
    if self.GameData:GetBossLevels(XColorTableConfigs.ColorType.Red) > 0 then
        self.BossDir[XColorTableConfigs.ColorType.Red] = XGridBoss.New(self.Boss3, XColorTableConfigs.ColorType.Red)
        table.insert(self.ShowBoss, self.BossDir[XColorTableConfigs.ColorType.Red])
    else
        self.Boss3.gameObject:SetActiveEx(false)
    end
    if self.GameData:GetBossLevels(XColorTableConfigs.ColorType.Green) > 0 then
        self.BossDir[XColorTableConfigs.ColorType.Green] = XGridBoss.New(self.Boss1, XColorTableConfigs.ColorType.Green)
        table.insert(self.ShowBoss, self.BossDir[XColorTableConfigs.ColorType.Green])
    else
        self.Boss1.gameObject:SetActiveEx(false)
    end
    if self.GameData:GetBossLevels(XColorTableConfigs.ColorType.Blue) > 0 then
        self.BossDir[XColorTableConfigs.ColorType.Blue] = XGridBoss.New(self.Boss2, XColorTableConfigs.ColorType.Blue)
        table.insert(self.ShowBoss, self.BossDir[XColorTableConfigs.ColorType.Blue])
    else
        self.Boss2.gameObject:SetActiveEx(false)
    end
end

function XUiColorTableStageBoss:_AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnEnter, self._OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGouxuan, self._OnBtnDonShowRollAnimClick)
end

function XUiColorTableStageBoss:_OnBtnCloseClick()
    self:Close()
    if self.CallBack then
        self.CallBack()
    end
end

function XUiColorTableStageBoss:_OnBtnDonShowRollAnimClick()
    self.GameManager:SetDontShowRollBoss(not self.GameManager:GetDontShowRollBoss())
end

----------------------------------------------------------------