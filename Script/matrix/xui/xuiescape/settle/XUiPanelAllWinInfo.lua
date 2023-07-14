--######################## XUiGridCond ########################
local XUiGridCond = XClass(nil, "XUiGridCond")

function XUiGridCond:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.EscapeData = XDataCenter.EscapeManager.GetEscapeDataCopy()
end

function XUiGridCond:Refresh(condType, desc)
    self.TxtDesc.text = desc
    local detailDesc
    if condType == XEscapeConfigs.ChapterSettleCondType.RemainTime then
        local remainTime = self.EscapeData:GetRemainTime()
        detailDesc = remainTime .. XUiHelper.GetText("Second")
    elseif condType == XEscapeConfigs.ChapterSettleCondType.HitTimes then
        detailDesc = XUiHelper.GetText("EscapeCount", self.EscapeData:GetAllHit())
    elseif condType == XEscapeConfigs.ChapterSettleCondType.TrapedTimes then
        detailDesc = XUiHelper.GetText("EscapeCount", self.EscapeData:GetAllTrapHit())
    end
    self.TxtDetails.text = detailDesc
end

--阶段结算
local XUiGridWinRole = require("XUi/XUiEscape/Settle/XUiGridWinRole")
local XUiPanelAllWinInfo = XClass(nil, "XUiPanelAllWinInfo")

function XUiPanelAllWinInfo:Ctor(ui, clickLeftCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)

    self.ClickLeftCb = clickLeftCb
    self.GridCondList = {}
    self.TeamMembers = {}
    self.EscapeData = XDataCenter.EscapeManager.GetEscapeDataCopy()
    self:InitClickCallback()
end

function XUiPanelAllWinInfo:InitClickCallback()
    XUiHelper.RegisterClickEvent(self, self.BtnBlock, self.OnBtnBlockClick)
end

function XUiPanelAllWinInfo:OnBtnBlockClick()
    local clickCb = function()
        if self.ClickLeftCb then
            self.ClickLeftCb()
        end
    end
    if not self.IsWin then
        clickCb()
        return
    end
    XDataCenter.EscapeManager.RequestEscapeSettleChapter(clickCb, clickCb)
end

function XUiPanelAllWinInfo:Refresh(isWin)
    self.IsWin = isWin
    if not self.EscapeData then
        return
    end
    local chapterId = self.EscapeData:GetChapterId()
    self.TxtChapterName.text = XEscapeConfigs.GetChapterName(chapterId)
    self.TxtSettle.text = isWin and XUiHelper.GetText("EscapeSettleWinTitle") or XUiHelper.GetText("EscapeSettleLoseTitle")
    self.TxtTips.text = isWin and XUiHelper.GetText("EscapeSettleLoseTitle") or XUiHelper.GetText("EscapeSettleLoseDesc")
    self:UpdateScore()
    self:UpdateCondContent()
    self:UpdateCharacter()
end

function XUiPanelAllWinInfo:UpdateScore()
    local score = self.EscapeData:GetScore()
    local gradeImgPath = XEscapeConfigs.GetChapterSettleRemainTimeGradeImgPath(score)
    self.RImgScore:SetRawImage(gradeImgPath)
end 

function XUiPanelAllWinInfo:UpdateCharacter()
    local team = XDataCenter.EscapeManager.GetTeam()
    local isShowDefaultRoleGrid = false
    for i, entityId in ipairs(team:GetEntityIds()) do
        local teamMember = self.TeamMembers[i]
        if not teamMember and XTool.IsNumberValid(entityId) then
            isShowDefaultRoleGrid = true
            local teamMemberObj = i == 1 and self.GridWinRole or XUiHelper.Instantiate(self.GridWinRole, self.PanelRoleContent)
            teamMember = XUiGridWinRole.New(teamMemberObj, i, true)
            self.TeamMembers[i] = teamMember
        end
        if teamMember then
            teamMember:Refresh(entityId)
        end
    end
    self.GridWinRole.gameObject:SetActiveEx(isShowDefaultRoleGrid)
end

function XUiPanelAllWinInfo:UpdateCondContent()
    local condDescList = XEscapeConfigs.GetChapterSettleCondDesc()
    for condType, desc in ipairs(condDescList) do
        local grid = self.GridCondList[condType]
        if not grid then
            local obj = condType == 1 and self.GridCond or XUiHelper.Instantiate(self.GridCond, self.PanelDataContent)
            grid = XUiGridCond.New(obj)
            self.GridCondList[condType] = grid
        end
        grid:Refresh(condType, desc)
    end
end

return XUiPanelAllWinInfo