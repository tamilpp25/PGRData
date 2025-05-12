---@class XUiGridChapterStage : XUiNode
---@field _Control XBlackRockChessControl
---@field Parent XUiBlackRockChessChapter
local XUiGridChapterStage = XClass(XUiNode, "XUiGridChapterStage")

local NORMAL = XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL
local HARD = XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD

function XUiGridChapterStage:OnStart(normalStageId, hardStageId, chapterId)
    self._NormalStageId = normalStageId
    self._HardStageId = hardStageId
    self._ChapterId = chapterId
    
    self.BtnNormal.CallBack = function()
        self:SwitchDifficulty(NORMAL)
    end
    self.BtnHard.CallBack = function()
        self:SwitchDifficulty(HARD)
    end
    self.BtnGiveup.CallBack = handler(self, self.OnBtnGiveupClick)
    self.BtnEnter.CallBack = handler(self, self.OnBtnEnterClick)
end

function XUiGridChapterStage:OnEnable()
    local isNormalCur = XTool.IsNumberValid(self._NormalStageId) and XMVCA.XBlackRockChess:IsCurStageId(self._NormalStageId) or false
    local isHardCur = XTool.IsNumberValid(self._HardStageId) and XMVCA.XBlackRockChess:IsCurStageId(self._HardStageId) or false
    if isHardCur then
        self:UpdateDifficulty(HARD)
    else
        self:UpdateDifficulty(NORMAL)
    end
    self:UpdateView()
    self._IsStageFightting = isNormalCur or isHardCur
    self.BtnGiveup.gameObject:SetActiveEx(self._IsStageFightting)
end

function XUiGridChapterStage:UpdateView()
    local normalScore = self._Control:GetStageScore(self._NormalStageId)
    local hardScore = XTool.IsNumberValid(self._HardStageId) and self._Control:GetStageScore(self._HardStageId) or 0
    local maxScore = math.max(normalScore, hardScore)

    self.TxtTitle.text = self._CurStageConfig.Name
    self.RImgBoss:SetRawImage(self._CurStageConfig.ShowIcon)
    self.PanelOngoing.gameObject:SetActiveEx(XMVCA.XBlackRockChess:IsCurStageId(self._CurStageConfig.Id))
    self.PanelDefeat.gameObject:SetActiveEx(self._Control:IsStagePass(self._CurStageConfig.Id))
    self.TxtScore.text = maxScore > 0 and tostring(maxScore) or ""

    local isNormalCur = XTool.IsNumberValid(self._NormalStageId) and XMVCA.XBlackRockChess:IsCurStageId(self._NormalStageId) or false
    local isHardCur = XTool.IsNumberValid(self._HardStageId) and XMVCA.XBlackRockChess:IsCurStageId(self._HardStageId) or false
    self._IsStageFightting = isNormalCur or isHardCur
    self.BtnGiveup.gameObject:SetActiveEx(self._IsStageFightting)

    if self._CurDifficulty == NORMAL then
        local star = self._Control:GetStageStar(self._CurStageConfig.Id)
        for i = 1, 3 do
            self["Off" .. i].gameObject:SetActiveEx(i > star)
            self["On" .. i].gameObject:SetActiveEx(i <= star)
        end
    end

    self:UpdateUnlock()
    self:UpdateRedPoint()
end

function XUiGridChapterStage:UpdateUnlock()
    self._IsHardUnlock, self._HardLockDesc = false, ""
    if XTool.IsNumberValid(self._HardStageId) then
        self._IsHardUnlock, self._HardLockDesc = XMVCA.XBlackRockChess:IsStageUnlock(self._HardStageId)
    end

    self._IsNormalUnlock, self._NormalLockDesc = XMVCA.XBlackRockChess:IsStageUnlock(self._NormalStageId)

    self.TxtLock.text = self._NormalLockDesc
    self.BtnNormal.gameObject:SetActiveEx(self._CurDifficulty ~= NORMAL)
    self.BtnHard.gameObject:SetActiveEx(self._IsHardUnlock and self._CurDifficulty == NORMAL)
    self.PanelLock.gameObject:SetActiveEx(not self._IsNormalUnlock)
end

function XUiGridChapterStage:UpdateRedPoint()
    self.RedPoint.gameObject:SetActiveEx(self._IsNormalUnlock and not self._Control:IsEverBeenEnterStage(self._NormalStageId))
    self.BtnHard:ShowReddot(self._IsHardUnlock and not self._Control:IsEverBeenEnterStage(self._HardStageId))
end

function XUiGridChapterStage:UpdateDifficulty(difficulty)
    local isNormal = difficulty == NORMAL
    self._CurDifficulty = difficulty
    self._CurStageConfig = self._Control:GetStageConfig(isNormal and self._NormalStageId or self._HardStageId)
    self.ListStar.gameObject:SetActiveEx(isNormal)
    self.ImgBg1.gameObject:SetActiveEx(isNormal)
    self.ImgBg2.gameObject:SetActiveEx(not isNormal)
end

function XUiGridChapterStage:SwitchDifficulty(difficulty)
    if self._IsStageFightting then
        XUiManager.TipError(XUiHelper.GetText("BlackRockChessDontSwitchStage"))
        return
    end
    
    local isNormal = difficulty == NORMAL
    if not isNormal and not self._IsHardUnlock then
        XUiManager.TipError(self._HardLockDesc)
        return
    end

    if not isNormal then
        self._Control:CloseStageRedPoint(self._NormalStageId)
        self._Control:CloseStageRedPoint(self._HardStageId)
    end

    self:PlayAnimation("GridChapterEnable")
    self:UpdateDifficulty(difficulty)
    self:UpdateView()
end

function XUiGridChapterStage:OnBtnGiveupClick()
    local content = self._Control:GetSecondaryConfirmationText(1)
    XLuaUiManager.Open("UiBlackRockChessTip", content, nil, function()
        self._Control:GiveUpStage(function(res)
            self:UpdateView()
            self._Control:SetGameRound(false)
            XLuaUiManager.Open("UiBlackRockChessVictorySettlement", self._CurStageConfig.Id, res.SettleResult)
        end)
    end)
end

function XUiGridChapterStage:OnBtnEnterClick()
    if self._CurDifficulty == NORMAL and not self._IsNormalUnlock then
        XUiManager.TipError(self._NormalLockDesc)
        return
    end
    if self._CurDifficulty == HARD and not self._IsHardUnlock then
        XUiManager.TipError(self._HardLockDesc)
        return
    end
    
    -- 战斗中 且 非本关卡
    if XMVCA.XBlackRockChess:IsInFight() and not XMVCA.XBlackRockChess:IsCurStageId(self._CurStageConfig.Id) then
        local values = self._Control:GetClientConfigValues("GiveUpStageTips")
        local content = values[1]
        local sureTxt = values[2]
        local cancleTxt = values[3]
        XLuaUiManager.Open("UiBlackRockChessTip", content, sureTxt, function()
            self._Control:GiveUpStage(function(res)
                self.Parent:UpdateChaptersView()
                self._Control:SetGameRound(false)
            end)
            self:OpenChapterDetail()
        end, cancleTxt)
    else
        self:OpenChapterDetail()
    end
end

function XUiGridChapterStage:OpenChapterDetail()
    self._Control:CloseStageRedPoint(self._NormalStageId)
    XLuaUiManager.Open("UiBlackRockChessChapterDetail", self._CurStageConfig.Id)
    
    -- 移动位置
    self.Parent:LocateToStage(self.Transform)
end

return XUiGridChapterStage