-- 调色战争关卡详情界面
local XUiColorTableStay = XLuaUiManager.Register(XLuaUi, "UiColorTableStay")

local MaxBossCnt = 4
local BossPos = 0 -- boss的位置

function XUiColorTableStay:OnAwake()
    self.StageId = nil -- 关卡id
    self.CaptainId = nil -- 队长id

    self:SetButtonCallBack()
    self:InitTimes()
end

function XUiColorTableStay:OnStart(stageId)
    self.StageId = stageId
    self.CaptainId = XColorTableConfigs.GetStageCaptainId(self.StageId)
    self.IsCfgCaptain = self.CaptainId ~= 0
end

function XUiColorTableStay:OnEnable()
    self.Super.OnEnable(self)
    self:Refresh()
end

function XUiColorTableStay:OnDisable()
    self.Super.OnDisable(self)
end

function XUiColorTableStay:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter, self.OnBtnEnterClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBossClick, self.OnBtnBossClick)
    XUiHelper.RegisterClickEvent(self, self.BtnChangeModel, self.OnBtnChangeModelClick)
end

function XUiColorTableStay:OnBtnEnterClick()
    if self.CaptainId == 0 then
        self:OnBtnChangeModelClick()
        return
    end
    
    XDataCenter.ColorTableManager.EnterStageGame(self.StageId, self.CaptainId)
end

function XUiColorTableStay:OnBtnBossClick()
    local buffCfgList = XColorTableConfigs.GetStageBuffConfigList(self.StageId)
    XLuaUiManager.Open("UiColorTableBuffDetail", buffCfgList)
end

function XUiColorTableStay:OnBtnChangeModelClick()
    if self.IsCfgCaptain then
        return
    end

    -- 打开选择领队界面
    XLuaUiManager.Open("UiColorTableManagerChoose", self.CaptainId, function(captainId)
        self.CaptainId = captainId
        self:RefreshCaptain()
    end)
end

function XUiColorTableStay:Refresh()
    self.TxtTitle.text = XColorTableConfigs.GetStageName(self.StageId)

    -- 刷新胜利条件
    self:RefreshWinCondition()

    -- 刷新boss列表
    self:RefreshBossList()

    -- 刷新关卡效果
    self:RefreshStageEffect()

    -- 刷新领队
    self:RefreshCaptain()
end

function XUiColorTableStay:RefreshWinCondition()
    local normalWinConditionId = XColorTableConfigs.GetStageNormalWinConditionId(self.StageId)
    local isShowNormal = normalWinConditionId ~= 0
    self.PanelNormal.gameObject:SetActiveEx(isShowNormal)
    if isShowNormal then
        self.TxtNormalCondition.text = XColorTableConfigs.GetWinConditionName(normalWinConditionId)
    end

    local specialWinConditionId = XColorTableConfigs.GetStageSpecialWinConditionId(self.StageId)
    local isShowSpecial = specialWinConditionId ~= 0
    self.PanelSpecial.gameObject:SetActiveEx(isShowSpecial)
    if isShowSpecial then
        self.TxtSpecialCondition.text = XColorTableConfigs.GetWinConditionName(specialWinConditionId)
    end
end

function XUiColorTableStay:RefreshBossList()
    local colorList = {}
    local normalWinConditionId = XColorTableConfigs.GetStageNormalWinConditionId(self.StageId)
    local isShowNormal = normalWinConditionId ~= 0
    if isShowNormal then
        table.insert(colorList, XColorTableConfigs.ColorType.Red)
        table.insert(colorList, XColorTableConfigs.ColorType.Green)
        table.insert(colorList, XColorTableConfigs.ColorType.Blue)
    end

    local specialWinConditionId = XColorTableConfigs.GetStageSpecialWinConditionId(self.StageId)
    local isShowSpecial = specialWinConditionId ~= 0
    if isShowSpecial then
        table.insert(colorList, XColorTableConfigs.HideBossColor)
    end

    local mapId = XColorTableConfigs.GetStageMapId(self.StageId)
    local pointGroupId = XColorTableConfigs.GetMapPointGroupId(mapId)
    for colorId = 0, MaxBossCnt - 1 do
        local config =  XColorTableConfigs.GetPointConfig(pointGroupId, BossPos, colorId)
        local isShow = table.contains(colorList, colorId) and config ~= nil
        self["GridBossItem"..colorId].gameObject:SetActiveEx(isShow)
        if isShow then
            self["RImgIconBoss"..colorId]:SetRawImage(config.Icon)
        end
    end
end

function XUiColorTableStay:RefreshStageEffect()
    local effectId = XColorTableConfigs.GetStageStageEffectId(self.StageId)
    local stageType = XColorTableConfigs.GetStageType(self.StageId)
    local isShow = effectId ~= 0 and stageType ~= XColorTableConfigs.StageType.FirstGuide and stageType ~= XColorTableConfigs.StageType.SecondGuide
    self.PanelEffect.gameObject:SetActiveEx(isShow)
    if isShow then
        local icon = XColorTableConfigs.GetStageEffectIcon(effectId)
        self.RImgIconEffect:SetRawImage(icon)
        self.TxtEffectName.text = XColorTableConfigs.GetStageEffectName(effectId)
        self.TxtEffectMassage.text = XColorTableConfigs.GetStageEffectDesc(effectId)
    end
end

function XUiColorTableStay:RefreshCaptain()
    local haveCaptain = self.CaptainId ~= 0
    self.RImgModel.gameObject:SetActiveEx(haveCaptain)
    self.ImgChange.gameObject:SetActiveEx(haveCaptain and not self.IsCfgCaptain)
    self.PanelAdd.gameObject:SetActiveEx(not haveCaptain)
    self.PanelCaptainSkill.gameObject:SetActiveEx(false)

    if haveCaptain then
        local config = XColorTableConfigs.GetColorTableCaptain(self.CaptainId)
        self.RImgModel:SetRawImage(config.Icon)

        local haveCaptainSkill = config.SkillName and config.SkillName ~= ""
        if haveCaptainSkill then
            self.PanelCaptainSkill.gameObject:SetActiveEx(true)
            self.RImgSkillIcon:SetRawImage(config.SkillIcon)
            self.TxtSkillName.text = config.SkillName
            self.TxtSkillDesc.text = config.SkillDesc
        end
    end
end

function XUiColorTableStay:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.ColorTableManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end