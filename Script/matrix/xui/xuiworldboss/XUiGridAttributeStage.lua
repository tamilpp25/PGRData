local XUiGridAttribute = require("XUi/XUiDorm/XUiDormCommom/XUiGridAttribute")
local stringFormat = string.format
local XUiGridAttributeStage = XClass(nil, "XUiGridAttributeStage")

function XUiGridAttributeStage:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsSelect = false
    self.Base = base
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self:SetSelectState(false)
end

function XUiGridAttributeStage:SetButtonCallBack()
    self.BtnStage.CallBack = function()
        self:OnBtnStageClick()
    end
    self.BtnBuff.CallBack = function()
        self:OnBtnBuffClick()
    end
end

function XUiGridAttributeStage:UpdateStageGrid(stageData)
    self.StageData = stageData
    if stageData then
        local stageCfg = stageData:GetStageCfg()
        local IsHaveBuff = false
        local percent = self.StageData:GetFinishPercent()
        local IsHaveRed = XDataCenter.WorldBossManager.CheckWorldBossStageRedPoint(self.Base.AreaId,stageData:GetId())
        self.StageIcon:SetRawImage(stageCfg.Icon)
        self.StageName.text = stageCfg.Name
        self.Schedule.fillAmount = percent
        self.ScheduleNum.text = string.format("%d%s",math.floor(percent * 100),"%")
        for _,buffId in pairs(stageData:GetBuffIds()) do
            self.BuffData = XDataCenter.WorldBossManager.GetWorldBossBuffById(buffId)
            if self.BuffData then
                IsHaveBuff = true
                self.BuffIcon:SetRawImage(self.BuffData:GetIcon())
                break
            end
        end

        self.PanelClear.gameObject:SetActiveEx(stageData:GetIsFinish())
        self.BuffLock.gameObject:SetActiveEx(not stageData:GetIsFinish())
        self.BuffActive.gameObject:SetActiveEx(stageData:GetIsFinish())
        self.PanelWorldBossRewardParent.gameObject:SetActiveEx(IsHaveBuff)
        self.PanelWorldBossLockParent.gameObject:SetActiveEx(stageData:GetIsLock())
        self.PanelWorldBossIngParent.gameObject:SetActiveEx(not stageData:GetIsLock() and not stageData:GetIsFinish())
        self.BtnStage:ShowReddot(IsHaveRed)
    end
end

function XUiGridAttributeStage:SetSelectState(IsSelect)
    self.ImageSelect.gameObject:SetActiveEx(IsSelect)
end

function XUiGridAttributeStage:OnBtnStageClick()
    if not self.StageData then
        return
    end
    
    if self.StageData:GetIsLock() then
        XUiManager.TipMsg(self.StageData:GetLockDesc())
        return
    end

    local curGrid = self.Base.CurStageGrid
    if curGrid and (curGrid.StageData:GetId() == self.StageData:GetId()) then
        return
    end
    -- 取消上一个选择
    if curGrid then
        curGrid:SetSelectState(false)
    end

    if not self.StageData:GetIsLock() then
        local storyId = self.StageData:GetStartStoryId()
        
        if storyId and #storyId > 1 then
            local IsCanPlay = XDataCenter.WorldBossManager.CheckIsNewStoryID(storyId)
            if IsCanPlay then
                XDataCenter.MovieManager.PlayMovie(storyId)--一次
                XDataCenter.WorldBossManager.MarkStoryID(storyId) 
            end
        end
    end

    self:SetSelectState(true)
    self.Base.CurStageGrid = self
    self.Base:MoveToStageGrid()
    XLuaUiManager.Open("UiWorldBossDetail", self.StageData, self.Base.AreaId, function ()
            self.Base:ScaleBack()
            self.Base.CurStageGrid = nil
            self:SetSelectState(false)
        end,function ()
            self:UpdateStageGrid(self.StageData)
        end)
end

function XUiGridAttributeStage:OnBtnBuffClick()
    XLuaUiManager.Open("UiWorldBossTips", self.BuffData:GetId(), true)
end

return XUiGridAttributeStage