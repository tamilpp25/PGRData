---@class XUiPokerGuessing2StoryGrid : XUiNode
---@field _Control XPokerGuessing2Control
local XUiPokerGuessing2StoryGrid = XClass(XUiNode, "XUiPokerGuessing2StoryGrid")

function XUiPokerGuessing2StoryGrid:OnStart()
    self.CanvasGroup = self.CanvasGroup or XUiHelper.TryGetComponent(self.Transform, "", "CanvasGroup")
    XUiHelper.RegisterClickEvent(self, self.Btnplay, self.OnClickPlay, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnGiveGifts, self.OnClickUnlock, nil, true)
    self._IsPlay = false
end

---@param data XUiPokerGuessing2StoryGridData
function XUiPokerGuessing2StoryGrid:Update(data)
    self.GameObject:SetActiveEx(self._IsPlay)
    self._Data = data
    self.NPCImg:SetRawImage(data.Icon)
    self.ArchiveNpcName.text = data.Name
    if data.IsUnlock then
        self.Btnplay.gameObject:SetActiveEx(true)
        self.BtnGiveGifts.gameObject:SetActiveEx(false)
    else
        self.Btnplay.gameObject:SetActiveEx(false)
        self.BtnGiveGifts.gameObject:SetActiveEx(true)
    end
end

function XUiPokerGuessing2StoryGrid:OnClickUnlock()
    self._Control:UnlockStory(self._Data)
end

function XUiPokerGuessing2StoryGrid:OnClickPlay()
    self._Control:PlayStory(self._Data)
end

function XUiPokerGuessing2StoryGrid:PlayEnableAnimation(index)
    self.GameObject:SetActiveEx(true)
    if self.GameObject.activeInHierarchy and not self._IsPlay then
        self.CanvasGroup.alpha = 0
        self._Timer = XScheduleManager.ScheduleOnce(function()
            self.CanvasGroup.alpha = 1
            self:PlayAnimation("AnimEnable", function()
                self._IsPlay = true
            end)
            self._Timer = false
        end, (index - 1) * 90)
    end
end

function XUiPokerGuessing2StoryGrid:OnDestroy()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

return XUiPokerGuessing2StoryGrid