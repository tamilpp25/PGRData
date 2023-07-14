--选择难度的难度grid
local XUiGuildBossLevelGrid = XClass(nil, "XUiGuildBossLevelGrid")

function XUiGuildBossLevelGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BtnSelect.CallBack = function() self:OnBtnSelectClick() end
end

function XUiGuildBossLevelGrid:Init(data, curLevel, nextLevel, rankLevel, highScore)
    self.Data = data
    self.TxtLv.text = CS.XTextManager.GetText("GuildBossDiffLv", data.Level)
    self.TxtBossHp.text = CS.XTextManager.GetText("GuildBossDiffHp", XUiHelper.GetLargeIntNumText(data.BossHp))
    self.TxtUnlockScore.text = CS.XTextManager.GetText("GuildBossDiffUnlock", XUiHelper.GetLargeIntNumText(data.UnlockScore))
    self.TxtAdditionPercent.text = CS.XTextManager.GetText("GuildBossDiffScoreAdd", data.AdditionPercent)
    --当前这一期所使用的Level标记
    if curLevel == data.Level then
        self.CurMark.gameObject:SetActiveEx(true)
    else
        self.CurMark.gameObject:SetActiveEx(false)
    end
    --只有会长和副会长能操作
    if rankLevel <= XGuildConfig.GuildRankLevel.CoLeader then
        --如果已解锁
        if highScore >= data.UnlockScore then
            self.FunctionGroup.gameObject:SetActiveEx(true)
            self.TxtGroup.alpha = 1
            --如果是下次选择的level
            if data.Level == nextLevel then
                self.NextSelectMark.gameObject:SetActiveEx(true)
                self.BtnSelect.gameObject:SetActiveEx(false)
            else
                self.NextSelectMark.gameObject:SetActiveEx(false)
                self.BtnSelect.gameObject:SetActiveEx(true)
            end
        --未解锁
        else
            self.TxtGroup.alpha = 0.8
            self.FunctionGroup.gameObject:SetActiveEx(false)
        end
    else
        self.FunctionGroup.gameObject:SetActiveEx(false)
        if highScore >= data.UnlockScore then
            self.TxtGroup.alpha = 1
            if data.Level == nextLevel then
                self.FunctionGroup.gameObject:SetActiveEx(true)
                self.NextSelectMark.gameObject:SetActiveEx(true)
                self.BtnSelect.gameObject:SetActiveEx(false)
            end
        else
            self.TxtGroup.alpha = 0.8
        end
    end
end

--更换下期level
function XUiGuildBossLevelGrid:OnBtnSelectClick()
    XDataCenter.GuildBossManager.GuildBossLevelRequest(self.Data.Level)
end

return XUiGuildBossLevelGrid