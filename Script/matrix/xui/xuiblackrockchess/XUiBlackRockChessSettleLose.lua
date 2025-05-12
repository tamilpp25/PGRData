
---@class XUiBlackRockChessSettleLose : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessSettleLose = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessSettleLose")

local GridLoseTip = require("XUi/XUiSettleLose/XUiGridLoseTip")

function XUiBlackRockChessSettleLose:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBlackRockChessSettleLose:OnStart(stageId)
    self.StageId = stageId
    self:SetTip()
    
    self:InitView()
end

function XUiBlackRockChessSettleLose:InitUi()
    self.BtnRestart.gameObject:SetActiveEx(false)
    self.BtnTongRed.gameObject:SetActiveEx(false)
    self.GridLoseTip.gameObject:SetActiveEx(false)
    self.TxtPeople.gameObject:SetActiveEx(false)

    self.BtnLose = self.Transform:Find("SafeAreaContentPane/PanelLose/BtnLose"):GetComponent("Button")
end

function XUiBlackRockChessSettleLose:InitCb()
    self:RegisterClickEvent(self.BtnLose, self.OnBtnLoseClick)
end

function XUiBlackRockChessSettleLose:InitView()

    self.TxtStageName.text = self._Control:GetStageName(self.StageId)
end

function XUiBlackRockChessSettleLose:SetTip()
    local tipId = self._Control:GetSettleLoseTipId()
    local tipDescList = XFubenConfigs.GetTipDescList(tipId)
    local skipList = XFubenConfigs.GetSkipIdList(tipId)
    tipDescList = tipDescList or {}
    for i, desc in pairs(tipDescList) do
        local obj = CS.UnityEngine.Object.Instantiate(self.GridLoseTip)
        obj.transform:SetParent(self.PanelTips.transform, false)
        obj.gameObject:SetActiveEx(true)
        GridLoseTip.New(obj, self, { ["TipDesc"] = desc, ["SkipId"] = skipList[i] })
    end
end

function XUiBlackRockChessSettleLose:OnBtnLoseClick()
    local chapterId, difficulty = self._Control:GetStageChapterIdAndDifficulty(self.StageId)
    XLuaUiManager.PopThenOpen("UiBlackRockChessChapter", chapterId, difficulty == XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL)
end
