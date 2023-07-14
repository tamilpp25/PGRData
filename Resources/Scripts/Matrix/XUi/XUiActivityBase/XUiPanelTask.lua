local BtnGoRedPointConditions = {
    [XActivityConfigs.TaskPanelSkipType.CanZhangHeMing_Qu] = { XRedPointConditions.Types.CONDITION_FUBEN_DRAGPUZZLEGAME_RED },
    [XActivityConfigs.TaskPanelSkipType.CanZhangHeMing_LuNa] = { XRedPointConditions.Types.CONDITION_FUBEN_DRAGPUZZLEGAME_RED },
    [XActivityConfigs.TaskPanelSkipType.ChrismasTree_Dress] = { XRedPointConditions.Types.CONDITION_CHRISTMAS_TREE },
    [XActivityConfigs.TaskPanelSkipType.Couplet_Game] = { XRedPointConditions.Types.CONDITION_COUPLET_GAME },
    [XActivityConfigs.TaskPanelSkipType.CanZhangHeMing_SP] = { XRedPointConditions.Types.CONDITION_FUBEN_DRAGPUZZLEGAME_RED },
    [XActivityConfigs.TaskPanelSkipType.InvertCard_Game] = { XRedPointConditions.Types.CONDITION_INVERTCARDGAME_RED },
}

local XUiPanelTask = XClass(nil, "XUiPanelTask")

function XUiPanelTask:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskActivityList)
    self.DynamicTable:SetProxy(XDynamicDailyTask)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelTask:Refresh(activityCfg)
    if not activityCfg then return end
    self.ActivityCfg = activityCfg
    self.TxtContentTimeTask.text = self:GetTxtContentTimeTask(activityCfg)
    self.TxtContentTitleTask.text = activityCfg.ActivityTitle
    self.TxtContentTask.text = activityCfg.ActivityDes

    local skipId = activityCfg.Params[2]
    if skipId and skipId ~= 0 then
        self.BtnGo.gameObject:SetActiveEx(true)
        CsXUiHelper.RegisterClickEvent(self.BtnGo, function()
            if XFunctionManager.CheckSkipInDuration(skipId) then
                XFunctionManager.SkipInterface(skipId)
            else
                XUiManager.TipText("ActivityBaseTaskSkipNotInDuring")
            end
        end)
        if not self.BtnGoRedPointIdDic then self.BtnGoRedPointIdDic = {} end
        if self.BtnGoRedPointIdDic[skipId] then
            XRedPointManager.Check(self.BtnGoRedPointIdDic[skipId])
        else
            if BtnGoRedPointConditions[skipId] and XFunctionManager.IsCanSkip(skipId) then
                self.BtnGoRedPointIdDic[skipId] = XRedPointManager.AddRedPointEvent(self.BtnGo, self.OnRedPointEvent, self, BtnGoRedPointConditions[skipId], nil, true)
            else
                self.BtnGo:ShowReddot(false)
            end
        end
    else
        self.BtnGo.gameObject:SetActiveEx(false)
    end

    self:UpdateDynamicTable()
end

function XUiPanelTask:GetTxtContentTimeTask(activityCfg)
    local taskGroupId = activityCfg.Params[1]
    local beginTime, endTime = XTaskConfig.GetTimeLimitTaskTime(taskGroupId)

    return XActivityConfigs.GetActivityTimeStr(activityCfg.Id, beginTime, endTime)
end

function XUiPanelTask:UpdateDynamicTable()
    self.TaskDatas = XDataCenter.ActivityManager.GetActivityTaskData(self.ActivityCfg.Id)
    self.ImgEmpty.gameObject:SetActive(#self.TaskDatas <= 0)
    self.DynamicTable:SetDataSource(self.TaskDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiPanelTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self.RootUi
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.TaskDatas[index]

        grid:ResetData(data)
        
        
    end
end

function XUiPanelTask:OnRedPointEvent(count)
    self.BtnGo:ShowReddot(count >= 0)
end

return XUiPanelTask