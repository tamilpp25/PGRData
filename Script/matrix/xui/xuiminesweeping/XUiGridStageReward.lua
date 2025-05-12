local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridStageReward = XClass(nil, "XUiGridStageReward")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridStageReward:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    self.IsPlayedAnime = true
    XTool.InitUiObject(self)
end

function XUiGridStageReward:UpdateGrid(data)
    self.Data = data
    if data then
        if not self.Reward then
            self.Reward = XUiGridCommon.New(self.Root, self.GridCommon)
        end
        
        local reward = XRewardManager.GetRewardList(data:GetRewardId())[1]
        self.Reward:Refresh(reward)

        self.HintText.text = CSTextManagerGetText("MineStageUnLockHint", data:GetName())
        self:ShowGrid()
    end
end

function XUiGridStageReward:ShowGrid()
    if not self.Data:IsFinish() then
        self.GameObject:SetActiveEx(true)
        self.GridCanvasGroup.alpha = 1
        self.IsPlayedAnime = false
    else
        if self.IsPlayedAnime or self.Root:IsChapterIndexChange() then
            self.GameObject:SetActiveEx(false)
        end
    end
end

function XUiGridStageReward:CheckPlayAnime()
    if self.Data:IsFinish() and not self.IsPlayedAnime and self.GameObject.activeInHierarchy then
        XLuaUiManager.SetMask(true)
        self.GridStageRewardDisable:PlayTimelineAnimation(function ()
                self.IsPlayedAnime = true
                XLuaUiManager.SetMask(false)
                self.Root:ShowFinishReward()
                self.GameObject:SetActiveEx(false)
            end)
    end
end

return XUiGridStageReward