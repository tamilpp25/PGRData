local XUiUnionKillEnterFight = XLuaUiManager.Register(XLuaUi, "UiUnionKillEnterFight")
local greyColor = CS.UnityEngine.Color(152 / 255, 152 / 255, 152 / 255, 1)
local blueColor = CS.UnityEngine.Color(15 / 255, 112 / 255, 188 / 255, 1)
local redColor = CS.UnityEngine.Color(208 / 255, 107 / 255, 33 / 255, 1)

function XUiUnionKillEnterFight:OnAwake()
    self.BtnMask.CallBack = function() self:OnBtnMaskClick() end
    self.BtnEnterFight.CallBack = function() self:OnBtnEnterFightClick() end
    self.BtnBossEnterFight.CallBack = function() self:OnBtnBossEnterFightClick() end
end

function XUiUnionKillEnterFight:OnDestroy()
end

function XUiUnionKillEnterFight:OnStart(stageId, sectionTemplate, stageType)
    self.StageId = stageId
    self.CurSectionTemplate = sectionTemplate
    self.StageType = stageType

    if self.StageType == XFubenUnionKillConfigs.UnionKillStageType.EventStage then
        self:PlayAnimation("GuanQiaFightEnable", function()
            XLuaUiManager.SetMask(false)
        end, function()
            XLuaUiManager.SetMask(true)
        end)
        self:OnOpenEventStageDetails()
    else
        self:PlayAnimation("BossFightEnable", function()
            XLuaUiManager.SetMask(false)
        end, function()
            XLuaUiManager.SetMask(true)
        end)
        self:OnOpenBossStageDetails()
    end
end

-- 事件关
function XUiUnionKillEnterFight:OnOpenEventStageDetails()
    self.PanelGuanQiaFight.gameObject:SetActiveEx(true)
    self.PanelBossFight.gameObject:SetActiveEx(false)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)

    self.TxtFightName.text = stageCfg.Name
    local eventStageTemplate = XFubenUnionKillConfigs.GetUnionEventStageById(self.StageId)
    if not eventStageTemplate then return end

    local buffId = eventStageTemplate.EventId[1]
    local buffConfig = XFubenUnionKillConfigs.GetUnionEventConfigById(buffId)
    self.RImgBuff:SetRawImage(buffConfig.Icon)
    self.TxtBuffDescription1.text = buffConfig.Description
    self.TxtBuffName.text = buffConfig.Name

    local extraBuffId = eventStageTemplate.EventId[2]
    local extraBuffConfig = XFubenUnionKillConfigs.GetUnionEventConfigById(extraBuffId)
    self.TxtBuffDescription2.text = extraBuffConfig.Description

    self.RoomFightData = XDataCenter.FubenUnionKillManager.GetCurRoomData()
    if not self.RoomFightData then
        self.TxtBuffDescription1.color = greyColor
        self.TxtBuffDescription2.color = greyColor
    else
        local stageInfos = self.RoomFightData.UnionKillStageInfos
        local curStageInfo = stageInfos[self.StageId]

        local meFinish = XDataCenter.FubenUnionKillManager.IsMeFinish(curStageInfo)
        local othersFinish = XDataCenter.FubenUnionKillManager.IsOthersFinish(curStageInfo)

        self.TxtBuffDescription1.color = meFinish and blueColor or greyColor
        self.TxtBuffDescription2.color = (meFinish and othersFinish) and blueColor or greyColor

        local textManager = CS.XTextManager
        -- 一级生效
        if meFinish then
            self.TxtBuffCondition1.color = blueColor
            self.TxtBuffCondition1.text = textManager.GetText("UnionEffectiveText")
        else
            self.TxtBuffCondition1.color = redColor
            self.TxtBuffCondition1.text = textManager.GetText("UnionMeFinishText")
        end

        -- 二级生效
        if meFinish and othersFinish then
            self.TxtBuffCondition1.color = greyColor
            self.TxtBuffDescription1.color = greyColor
            self.TxtBuffCondition1.text = textManager.GetText("UnionInvalidText")

            self.TxtBuffCondition2.color = blueColor
            self.TxtBuffCondition2.text = textManager.GetText("UnionEffectiveText")
        else
            if not meFinish then
                self.TxtBuffCondition1.color = redColor
            end
            self.TxtBuffCondition2.color = redColor
            self.TxtBuffCondition2.text = textManager.GetText("UnionTeamFinishText")
        end
    end
end

-- boss关 + 试炼关
function XUiUnionKillEnterFight:OnOpenBossStageDetails()
    self.PanelGuanQiaFight.gameObject:SetActiveEx(false)
    self.PanelBossFight.gameObject:SetActiveEx(true)

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local sectionConfig = XFubenUnionKillConfigs.GetUnionSectionConfigById(self.CurSectionTemplate.Id)
    self.TxtBossFightName.text = stageCfg.Name
    if self.StageType == XFubenUnionKillConfigs.UnionKillStageType.BossStage then
        self.RImgBossShiLian:SetRawImage(sectionConfig.BossIcon)
    else
        self.RImgBossShiLian:SetRawImage(sectionConfig.TrialIcon)
    end
    self.TxtAttributeTitle.text = sectionConfig.BossBuffName
    self.TxtAttributeDescription.text = sectionConfig.BossBuffText
end

function XUiUnionKillEnterFight:OnBtnMaskClick()
    self:Close()
end

-- 事件关
function XUiUnionKillEnterFight:OnBtnEnterFightClick()
    -- 是否重复打
    if not self.RoomFightData or not self.StageId then return end
    local stageInfos = self.RoomFightData.UnionKillStageInfos
    local curStageInfo = stageInfos[self.StageId]
    local meFinish = XDataCenter.FubenUnionKillManager.IsMeFinish(curStageInfo)
    if meFinish then
        XUiManager.TipMsg(CS.XTextManager.GetText("UnionHadFightEventStage"))
        return
    end

    self:Close()
    XLuaUiManager.Open("UiBattleRoleRoom", self.StageId)
end

function XUiUnionKillEnterFight:OnBtnBossEnterFightClick()
    if not self.StageId then return end
    -- 根据类型处理
    self:Close()
    XLuaUiManager.Open("UiBattleRoleRoom", self.StageId)
end