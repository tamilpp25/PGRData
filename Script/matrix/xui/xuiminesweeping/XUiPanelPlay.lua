local XUiPanelPlay = XClass(nil, "XUiPanelPlay")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiPanelPlay:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiPanelPlay:SetButtonCallBack()
    self.BtnPlay.CallBack = function()
        self:OnBtnPlayClick()
    end
end

function XUiPanelPlay:OnBtnPlayClick()
    XDataCenter.MovieManager.PlayMovie(self.StoryId)
    XDataCenter.MineSweepingManager.MarkStoryRed(self.ChapterId)
    XEventManager.DispatchEvent(XEventId.EVENT_MINESWEEPING_STORYPLAY)
end


function XUiPanelPlay:UpdatePanel(curCharterIndex)
    if curCharterIndex then
        local chapterEntity = XDataCenter.MineSweepingManager.GetChapterEntityByIndex(curCharterIndex)
        local img = chapterEntity:GetCompleteImg()
        self.ChapterId = chapterEntity:GetChapterId()
        self.RImgBg:SetRawImage(img)
        self.StoryId = chapterEntity:GetCompleteStoryId()
        self.PanelInfo.gameObject:SetActiveEx(self.StoryId ~= nil)
    end
end

function XUiPanelPlay:ShowPanel(IsShow)
    self.GameObject:SetActiveEx(IsShow)
    if IsShow then
        if self.StoryId ~= nil then
            self.Base:PlayAnimationWithMask("PanelPlayEnable",function ()
                    self.Base:PlayAnimation("PanelPlayLoop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
                end)
        else
            self.Base:PlayAnimationWithMask("PanelPlayEnable2")
        end
    end
end

return XUiPanelPlay