local XUiPanelSequenceWin = XClass(nil, "XUiPanelSequenceWin")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiPanelSequenceWin:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiPanelSequenceWin:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiPanelSequenceWin:OnBtnCloseClick()
    self.Base:SetSpecialState(XMineSweepingConfigs.SpecialState.None)
end

function XUiPanelSequenceWin:UpdatePanel()
    local SpecialStateChapterId = self.Base:GetSpecialStateChapterId()
    if SpecialStateChapterId then
        local chapterEntity = XDataCenter.MineSweepingManager.GetChapterEntityById(SpecialStateChapterId)
        self.HintText.text = CSTextManagerGetText("MineSweepingChapterWinHint",chapterEntity:GetChallengeCounts())
    end
end

function XUiPanelSequenceWin:ShowPanel(IsShow)
    self.GameObject:SetActiveEx(IsShow)
    if IsShow then
        self.Base:PlayAnimationWithMask("PanelSequenceWinEnable",function ()
                self.Base:PlayAnimation("PanelSequenceWinLoop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
        end)
    end
end

return XUiPanelSequenceWin