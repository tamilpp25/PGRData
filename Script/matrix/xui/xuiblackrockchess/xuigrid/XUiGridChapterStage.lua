---@class XUiGridChapterStage : XUiNode
---@field _Control XBlackRockChessControl
local XUiGridChapterStage = XClass(XUiNode, "XUiGridChapterStage")

function XUiGridChapterStage:OnStart()

end

function XUiGridChapterStage:SetData(stageId, lastStageId, curStageId, index)
    self._StageId = stageId
    self._IsUnlock = true
    if XTool.IsNumberValid(lastStageId) then
        self._IsUnlock = self._Control:IsStagePass(lastStageId)
    end
    
    self.BtnChess:SetDisable(not self._IsUnlock)

    local difficulty = self._Control:GetStageDifficulty(self._StageId)
    local star = self._Control:GetStageStar(self._StageId)

    if difficulty == XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD then
        self.PanelStar.gameObject:SetActiveEx(true)
        for i = 1, 3 do
            local go = self["Star" .. i]
            if go then
                local uiObject = {}
                XTool.InitUiObjectByUi(uiObject, go)
                uiObject.ImgStarDisable.gameObject:SetActiveEx(star < i)
                uiObject.ImgStarNor.gameObject:SetActiveEx(star >= i)
            end
        end
    else
        self.PanelStar.gameObject:SetActiveEx(false)
    end

    local val = string.format("%02d", index)
    
    
    self.BtnChess:SetNameByGroup(0, val)
    self.BtnChess:SetRawImage(self._Control:GetStageIcon(stageId))

    if self.ImgNow then
        self.ImgNow.gameObject:SetActiveEx(curStageId == stageId)
    end

    if self.ImgClear then
        if difficulty == XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL then
            local isPass = self._Control:IsStagePass(self._StageId)
            self.ImgClear.gameObject:SetActiveEx(isPass)
        elseif difficulty == XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD then
            self.ImgClear.gameObject:SetActiveEx(star >= 3)
        end
    end

    if self.ImgLock then
        self.ImgLock.gameObject:SetActiveEx(not self._IsUnlock)
    end
end

function XUiGridChapterStage:DoClick()
    if self._IsUnlock then
        XLuaUiManager.Open("UiBlackRockChessChapterDetail", self._StageId)
        return true
    else
        XUiManager.TipMsg(XUiHelper.GetText("BlackRockChessStageUnlock"))
        return false
    end
end

return XUiGridChapterStage