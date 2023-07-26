local XUiGridBtnBossArea = XClass(nil, "XUiGridBtnBossArea")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridBtnBossArea:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self:SetButtonCallBack()
end

function XUiGridBtnBossArea:SetButtonCallBack()
    self.BtnBoss.CallBack = function()
        self:OnBtnBossClick()
    end
end

function XUiGridBtnBossArea:OnBtnBossClick()
    if self.Data:GetIsLock() then
        local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity() 
        local finishStageCount = worldBossActivity:GetFinishStageCount()
        local hintText = CS.XTextManager.GetText("WorldBossBossAreaUnLockHint", finishStageCount, self.Data:GetOpenCount())
        XUiManager.TipMsg(hintText)
        return
    end
    if not self.Data:GetIsFinish() then
        local storyId = self.Data:GetStartStoryId()
        if storyId and #storyId > 1 then
            local IsCanPlay = XDataCenter.WorldBossManager.CheckIsNewStoryID(storyId)
            if IsCanPlay then
                XDataCenter.MovieManager.PlayMovie(storyId)--一次
                XDataCenter.WorldBossManager.MarkStoryID(storyId)
            end
        end
    end
    XLuaUiManager.Open("UiWorldBossBossArea", self.Data:GetId())
end

function XUiGridBtnBossArea:UpdateData(data)
    self.Data = data
    if data then
        local hpPercent = data:GetHpPercent()
        local IsHaveRed = XDataCenter.WorldBossManager.CheckWorldBossBossArearRedPoint(data:GetId())
        
        self.Title.text = CSTextManagerGetText("WorldBossBossAreaSchedule")
        self.PercentageText.text = string.format("%d%s",math.floor(hpPercent * 100),"%")
        if data:GetIsLock() then
            self.BtnBoss:SetSprite(data:GetAreaLockImg())
        else
            self.BtnBoss:SetSprite(data:GetAreaImg())
        end
        self.BtnBoss:SetDisable(data:GetIsLock())
        self.Handle.fillAmount = hpPercent
        self.Progress.gameObject:SetActiveEx(not data:GetIsLock())
        self.BtnBoss:ShowReddot(IsHaveRed)
        self.KillText.gameObject:SetActiveEx(hpPercent == 0)
        self.Title.gameObject:SetActiveEx(hpPercent ~= 0)
    end
end

function XUiGridBtnBossArea:ShowRedPoint(IsShow)
    self.BtnBoss:ShowReddot(IsShow)
end

return XUiGridBtnBossArea