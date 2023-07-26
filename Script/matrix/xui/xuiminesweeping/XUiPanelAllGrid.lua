local XUiPanelAllGrid = XClass(nil, "XUiPanelAllGrid")
local XUiGridMine = require("XUi/XUiMineSweeping/XUiGridMine")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiPanelAllGrid:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self.AllGridList = {}
    self.GridMine.gameObject:SetActiveEx(false)
end

function XUiPanelAllGrid:UpdatePanel(curCharterIndex, IsSpecialStateWin)
    if curCharterIndex and not IsSpecialStateWin then
        local chapterEntity = XDataCenter.MineSweepingManager.GetChapterEntityByIndex(curCharterIndex)
        local stageEntity = chapterEntity:GetCurStageEntity()
        local rowCount = stageEntity:GetRowCount()
        local columnCount = stageEntity:GetColumnCount()

        for y = 1, rowCount do
            for x = 1, columnCount do
                local gridEntity = chapterEntity:GetGridEntityByPos(x, y)
                local key = XMineSweepingConfigs.GetGridKeyByPos(x, y)
                if not self.AllGridList[key] then
                    local obj = CS.UnityEngine.Object.Instantiate(self.GridMine, self.PanelCase)
                    obj.gameObject:SetActiveEx(true)
                    self.AllGridList[key] = XUiGridMine.New(obj, self.Base)
                end
                self.AllGridList[key]:UpdateGrid(gridEntity, chapterEntity:GetChapterId(), stageEntity:GetStageId())
            end
        end

        if chapterEntity:IsSweeping()then
            if self.IsCanPlayAnime == nil then
                self.IsCanPlayAnime = not self.Base:IsChapterIndexChange()
            end
        else
            self.IsCanPlayAnime = nil
        end
    end
end

function XUiPanelAllGrid:ShowPanel(IsShow)
    self.GameObject:SetActiveEx(IsShow)
    if IsShow then
        if self.IsCanPlayAnime then
            self.Base:PlayAnimationWithMask("GridMineEnable")
            self.IsCanPlayAnime = false
        end
    else
        self:ResetEffect()
    end
end

function XUiPanelAllGrid:ShowEffect(cb)
    for _,grid in pairs(self.AllGridList) do
        grid:ShowEffect()
    end

    self.EffectTimer = XScheduleManager.ScheduleOnce(function()
            self.EffectTimer = nil
            self:ShowWinEffect(cb)
        end, XScheduleManager.SECOND / 2)
end

function XUiPanelAllGrid:ShowWinEffect(cb)
    local SpecialStateChapterId = self.Base:GetSpecialStateChapterId()
    local SpecialStateStageId = self.Base:GetSpecialStateStageId()
    local chapterEntity = XDataCenter.MineSweepingManager.GetChapterEntityById(SpecialStateChapterId)
    local stageEntity = chapterEntity:GetStageEntityById(SpecialStateStageId)

    self.WinEffect:LoadUiEffect(stageEntity:GetWinEffect())
    self.WinEffect.gameObject:SetActiveEx(true)
    self.EffectTimer = XScheduleManager.ScheduleOnce(function()
            self.EffectTimer = nil
            self.WinEffect.gameObject:SetActiveEx(false)
            if cb then cb() end
        end, XScheduleManager.SECOND)
end

function XUiPanelAllGrid:ResetEffect()
    for _,grid in pairs(self.AllGridList) do
        grid:ResetEffect()
    end
    if self.EffectTimer then
        XScheduleManager.UnSchedule(self.EffectTimer)
        return true
    end
    return false
end

return XUiPanelAllGrid