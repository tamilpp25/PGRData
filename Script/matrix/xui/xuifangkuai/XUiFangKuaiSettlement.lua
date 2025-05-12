---@class XUiFangKuaiSettlement : XLuaUi 结算弹框
---@field _Control XFangKuaiControl
local XUiFangKuaiSettlement = XLuaUiManager.Register(XLuaUi, "UiFangKuaiSettlement")

function XUiFangKuaiSettlement:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.OnClickBack)
    self:RegisterClickEvent(self.BtnBack, self.OnClickBack)
    self:RegisterClickEvent(self.BtnRePlay, self.OnClickRePlay)
end

function XUiFangKuaiSettlement:OnStart(stageId, restartCallBack, isAdvanceEnd)
    self._StageId = stageId
    self._StageConfig = self._Control:GetStageConfig(self._StageId)
    self._StageGroup = self._Control:GetStageGroupByStage(self._StageId)
    local settleData = self._Control:GetCurStageSettleData()
    self._IsNormal = self._Control:IsStageNormal(self._StageId)
    self._IsGoToDifficult = self._IsNormal and XTool.IsNumberValid(self._StageGroup.DiffcultStageId)
    self.TxtDamage.text = settleData.Point
    self.RankIcon:SetRawImage(self._Control:GetStageRankIcon(self._StageId, settleData.Point))
    self.NewRecord1.gameObject:SetActiveEx(settleData.IsNewScoreRecord)
    self.NewRecord2.gameObject:SetActiveEx(settleData.IsNewRoundRecord)
    self.BtnRePlay.gameObject:SetActiveEx(XLuaUiManager.IsUiShow("UiFangKuaiFight"))
    self.TxtRound.text = settleData.Round
    local SettleDesc = self._StageConfig.SettleDesc
    -- 困难+不提前结算+到达最大回合+有配置文本=显示
    if SettleDesc and SettleDesc ~= "" then
        self.TxtRankMax.text = SettleDesc
        self.TxtRankMax.gameObject:SetActiveEx(not self._IsNormal and not isAdvanceEnd and settleData.Round >= self._StageConfig.MaxRound)
    else
        self.TxtRankMax.gameObject:SetActiveEx(false)
    end
    self._RestartCallBack = restartCallBack
    self.BtnRePlay:SetNameByGroup(0, XUiHelper.GetText(self._IsGoToDifficult and "FangKuaiGoToDifficult" or "FangKuaiRestart"))
    self._Control:PlaySettleSound(self._StageId, settleData.Point)
end

function XUiFangKuaiSettlement:OnClickRePlay()
    if self._IsGoToDifficult then
        self._Control:ClearFightData(self._StageId)
        self:Close()
        if XLuaUiManager.IsUiLoad("UiFangKuaiChapterDetail") then
            XLuaUiManager.Close("UiFangKuaiFight")
            ---@type XUiFangKuaiChapterDetail
            local panel = XLuaUiManager.GetTopLuaUi("UiFangKuaiChapterDetail")
            panel:SelectDifficult()
        else
            -- 如果有关卡正在进行 点击关卡会直接进入战斗 这时不会打开UiFangKuaiChapterDetail界面
            XLuaUiManager.Open("UiFangKuaiChapterDetail", self._StageGroup.Id, XEnumConst.FangKuai.DifficultTab)
            XLuaUiManager.Remove("UiFangKuaiFight")
        end
    else
        self:Close()
        if self._RestartCallBack then
            self._RestartCallBack()
        end
    end
end

function XUiFangKuaiSettlement:OnClickBack()
    self._Control:ClearFightData(self._StageId)
    self:Close()
    XLuaUiManager.Remove("UiFangKuaiChapterDetail")
    XLuaUiManager.Close("UiFangKuaiFight")
end

return XUiFangKuaiSettlement