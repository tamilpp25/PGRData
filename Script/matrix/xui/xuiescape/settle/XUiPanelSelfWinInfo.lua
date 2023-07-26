--######################## XUiGridCond ########################
local XUiGridCond = XClass(nil, "XUiGridCond")

function XUiGridCond:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.EscapeData = XDataCenter.EscapeManager.GetEscapeData()
end

function XUiGridCond:Refresh(cordType, desc, stageId)
    self.TxtSelfDesc.text = XEscapeConfigs.GetFightSettleCondDesc(cordType)

    local desc
    if cordType == XEscapeConfigs.FightSettleCondType.StageName then
        desc = XFubenConfigs.GetStageName(stageId)
    elseif cordType == XEscapeConfigs.FightSettleCondType.Score then
        local score = self.EscapeData:GetScore()
        local grade = XEscapeConfigs.GetChapterSettleRemainTimeGrade(score)
        desc = score .. XUiHelper.GetText("EscapeSettleWinGrade", grade)
    end
    self.TxtSelfDate.text = desc or ""
end

--######################## XUiPanelSelfWinInfo ########################
local XUiGridWinRole = require("XUi/XUiEscape/Settle/XUiGridWinRole")
local ToInt = XMath.ToInt
local RemainTimeDelay = 1170    --打开界面等待动画播完（延迟毫秒）

--战后结算
local XUiPanelSelfWinInfo = XClass(nil, "XUiPanelSelfWinInfo")

function XUiPanelSelfWinInfo:Ctor(ui, clickLeftCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)

    self.ClickLeftCb = clickLeftCb
    self.CordGrids = {}
    self.TeamMembers = {}
    self.EscapeData = XDataCenter.EscapeManager.GetEscapeData()
    self:InitClickCallback()

    if self.Title then
        self.Title.text = XUiHelper.GetText("EscapeWinSettleDesc")
    end
    self.TxtAddCanvasGroup = self.TxtAdd:GetComponent("CanvasGroup")
    self.TxtBtAddCanvasGroup = self.TxtBtAdd:GetComponent("CanvasGroup")
    self:AddEventListener()
    self:SetImgTimeEffectActive(false)
end

function XUiPanelSelfWinInfo:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_ESCAPE_DATA_NOTIFY, self.UpdateByNotify, self)
end

function XUiPanelSelfWinInfo:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_ESCAPE_DATA_NOTIFY, self.UpdateByNotify, self)
end

function XUiPanelSelfWinInfo:InitClickCallback()
    XUiHelper.RegisterClickEvent(self, self.BtnLeft, self.ClickLeftCb)
end

function XUiPanelSelfWinInfo:Refresh(winData)
    self.WinData = winData

    local stageId = winData.StageId
    self.TxtAdd.text = string.format("+%sS", XEscapeConfigs.GetStageAwardTime(stageId))
    if self.TxtBtAdd then
        self.TxtBtAdd.text = XUiHelper.GetText("EscapeWinSettleRewardTitle")
    end

    local awardTime = XEscapeConfigs.GetStageAwardTime(self.WinData.StageId)
    local remainTime = self.EscapeData:GetRemainTime()
    self.TxtTime.text = XUiHelper.GetTime(remainTime - awardTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)

    self:UpdateByNotify()
    XScheduleManager.ScheduleOnce(handler(self, self.UpdateRemainTime), RemainTimeDelay)
end

function XUiPanelSelfWinInfo:UpdateByNotify()
    self:UpdateCord()
    self:UpdateCharacter()
end

function XUiPanelSelfWinInfo:UpdateCord()
    if not self.WinData then
        return
    end
    local stageId = self.WinData.StageId
    local descList = XEscapeConfigs.GetFightSettleCondDesc()
    for cordType, desc in ipairs(descList) do
        local cordGrid = self.CordGrids[cordType]
        if not cordGrid then
            local grid = cordType == 1 and self.GridCond or XUiHelper.Instantiate(self.GridCond, self.PanelSelfContent)
            cordGrid = XUiGridCond.New(grid)
        end
        cordGrid:Refresh(cordType, desc, stageId)
    end
end

function XUiPanelSelfWinInfo:UpdateRemainTime()
    if not self.WinData or XTool.UObjIsNil(self.Transform) then
        return
    end
    if self.PanelSelfWinInfoEnable then
        self.PanelSelfWinInfoEnable.gameObject:SetActiveEx(false)
    end

    local remainTime = self.EscapeData:GetRemainTime()
    local preRemainTime = self.EscapeData:GetOldRemainTime()
    local awardTime = remainTime - preRemainTime
    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    self.TxtTime.text = XUiHelper.GetTime(preRemainTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
    self:SetImgTimeEffectActive(true)

    XUiHelper.Tween(time, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        self.TxtTime.text = XUiHelper.GetTime(ToInt(preRemainTime + f * awardTime), XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
        self:SetTxtAddAlpha(1 - f)
    end,
    function()
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        self.TxtTime.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
        self:SetTxtAddAlpha(0)
    end)
end

function XUiPanelSelfWinInfo:SetTxtAddAlpha(alpha)
    self.TxtAddCanvasGroup.alpha = alpha
    self.TxtBtAddCanvasGroup.alpha = alpha
end

function XUiPanelSelfWinInfo:SetImgTimeEffectActive(isActive)
    if not self.ImgTimeEffect then
        return
    end
    self.ImgTimeEffect.gameObject:SetActiveEx(false)
    self.ImgTimeEffect.gameObject:SetActiveEx(isActive)
end

function XUiPanelSelfWinInfo:UpdateCharacter()
    local team = XDataCenter.EscapeManager.GetTeam()
    for i, entityId in ipairs(team:GetEntityIds()) do
        local teamMember = self.TeamMembers[i]
        if not teamMember and XTool.IsNumberValid(entityId) then
            local teamMemberObj = i == 1 and self.GridWinRole or XUiHelper.Instantiate(self.GridWinRole, self.PanelRoleContent)
            teamMember = XUiGridWinRole.New(teamMemberObj, i)
            self.TeamMembers[i] = teamMember
        end
        if teamMember then
            teamMember:Refresh(entityId, self.WinData)
        end
    end
end

return XUiPanelSelfWinInfo