local tableInsert = table.insert

local BTN_INDEX = {
    First = 1,
    Second = 2
}

local XUiDoomsdayFubenTask = XLuaUiManager.Register(XLuaUi, "UiDoomsdayFubenTask")

function XUiDoomsdayFubenTask:OnAwake()
    self:AddListener()
end

function XUiDoomsdayFubenTask:OnStart(stageId)
    --self.SelectIndex = 1
    self.StageId = stageId
    self.StageData = XDataCenter.DoomsdayManager.GetStageData(self.StageId)

    --self.BtnTargetIdDic = {}

    self:InitView()
end

function XUiDoomsdayFubenTask:OnEnable()
    --self.PanelTab:SelectIndex(self.SelectIndex)
end

function XUiDoomsdayFubenTask:InitView()
    --XDoomsdayConfigs.TargetConfig
    local stageData = self.StageData
    local mainTargetId = XDoomsdayConfigs.StageConfig:GetProperty(self.StageId, "MainTaskId")
    local config = XDoomsdayConfigs.TargetConfig:GetConfig(mainTargetId)
    --任务名
    self.TxtReport.text = config.Name
    --任务Tips
    self:RefreshTemplateGrids(
            self.TxtNewsInhabitant,
            config.Tips,
            self.ContentNewInhabitant,
            nil,
            "TaskDescGrids",
            function(grid, desc) 
                grid.TxtNewsInhabitant.text = desc
            end
    )
    --任务描述
    self.TxtDescSub.text = config.Desc
    --是否通关
    local passed = stageData:IsTargetFinished(mainTargetId)
    self.ImgGradeStarActive.gameObject:SetActiveEx(passed)
    self.ImgGradeStarUnactive.gameObject:SetActiveEx(not passed)

    --任务进度
    self:BindViewModelPropertiesToObj(
            stageData:GetTarget(mainTargetId),
            function(value, maxValue)
                self.TxtProgressNumSub.text = string.format("<color=#1b3750><size=28>%s</size></color>/%s", value, maxValue)
                self.ImgProgressSub.fillAmount = XUiHelper.GetFillAmountValue(value, maxValue)
            end,
            "_Value",
            "_MaxValue"
    )
end

function XUiDoomsdayFubenTask:AddListener()
    local closeFunc = handler(self, self.Close)
    self.BtnTanchuangCloseBig.CallBack = closeFunc
    --self.BtnBg.CallBack = closeFunc
    --self.BtnGiveUp.CallBack = handler(self, self.OnClickBtnGiveUp)
end

--==============================
 ---@desc 废弃的方法
--==============================
function XUiDoomsdayFubenTask:InitViewDiscard()
    --local stageData = self.StageData
    --
    --local btns = {}
    --local btnIndex = 1
    --
    ----一级标题
    --local targeGroup = stageData:GetTargetGroup()
    --for index, targeIdList in ipairs(targeGroup) do
    --    local targeIdCount = #targeIdList
    --    if targeIdCount ~= 0 then
    --        local btnModel = self:GetCertainBtnModel(BTN_INDEX.First, targeIdCount > 1)
    --        local btn = XUiHelper.Instantiate(btnModel, self.BtnContent)
    --        btn.gameObject:SetActiveEx(true)
    --
    --        local uiButton = btn:GetComponent("XUiButton")
    --        tableInsert(btns, uiButton)
    --        if index == BTN_INDEX.First then
    --            self.BtnTargetIdDic[btnIndex] = targeIdList[1]
    --            btn:SetName(CsXTextManagerGetText("DoomsdayTaskMain"))
    --        else
    --            btn:SetName(CsXTextManagerGetText("DoomsdayTaskSub"))
    --        end
    --        btnIndex = btnIndex + 1
    --
    --        --二级标题
    --        local firstIndex = btnIndex
    --        for i, targeId in ipairs(targeIdList) do
    --            local tmpBtnModel = self:GetCertainBtnModel(BTN_INDEX.Second, nil, i, targeIdCount)
    --            local tmpBtn = XUiHelper.Instantiate(tmpBtnModel, self.BtnContent)
    --            tmpBtn:SetName(XDoomsdayConfigs.TargetConfig:GetProperty(targeId, "Name"))
    --            tmpBtn.gameObject:SetActiveEx(true)
    --
    --            local tmpUiButton = tmpBtn:GetComponent("XUiButton")
    --            tmpUiButton.SubGroupIndex = firstIndex
    --            tableInsert(btns, tmpUiButton)
    --            btnIndex = btnIndex + 1
    --
    --            tmpUiButton:ShowReddot(false)
    --
    --            self.BtnTargetIdDic[btnIndex] = targeId
    --        end
    --    end
    --end
    --
    --self.PanelTab:Init(
    --    btns,
    --    function(index)
    --        self:OnSelectedTog(index)
    --    end
    --)
end

--==============================
 ---@desc 废弃的方法
--==============================
function XUiDoomsdayFubenTask:OnSelectedTog(index)
    --self.SelectIndex = index
    --
    --local stageId = self.StageId
    --local targetId = self.BtnTargetIdDic[self.SelectIndex]
    --local target = self.StageData:GetTarget(targetId)
    --
    --if index == BTN_INDEX.First then
    --    --主要目标
    --    targetId = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "MainTaskId")
    --
    --    self.TxtAim1.text = XDoomsdayConfigs.TargetConfig:GetProperty(targetId, "Desc")
    --
    --    local value, maxValue = target:GetProperty("_Value"), target:GetProperty("_MaxValue")
    --    self.TxtAim1Num.text = CsXTextManagerGetText("DoomsdayMainTargetProgress", value, maxValue)
    --    self.ImgProgressAim1.fillAmount = XUiHelper.GetFillAmountValue(value, maxValue)
    --
    --    --主要目标通关提示
    --    self:RefreshTemplateGrids(
    --        self.MainTxtTips,
    --        XDoomsdayConfigs.TargetConfig:GetProperty(targetId, "Tips"),
    --        self.MainTipsContent,
    --        nil,
    --        "MainTargetTipGrids",
    --        function(grid, tips)
    --            local target = self.StageData:GetTarget(targetId)
    --            grid.MainTxtTips.text = tips
    --        end
    --    )
    --
    --    --次要目标
    --    self:RefreshTemplateGrids(
    --        {
    --            self.GridStageStar1,
    --            self.GridStageStar2,
    --            self.GridStageStar3
    --        },
    --        XDoomsdayConfigs.StageConfig:GetProperty(stageId, "SubTaskId"),
    --        nil,
    --        nil,
    --        "SubTargetGrids",
    --        function(grid, targetId)
    --            local target = self.StageData:GetTarget(targetId)
    --
    --            grid.TxtActive.text = XDoomsdayConfigs.TargetConfig:GetProperty(targetId, "Desc")
    --            grid.TxtUnActive.text = XDoomsdayConfigs.TargetConfig:GetProperty(targetId, "Desc")
    --
    --            grid.PanelActive.gameObject:SetActiveEx(true)
    --            grid.PanelUnActive.gameObject:SetActiveEx(false)
    --
    --            local value, maxValue = target:GetProperty("_Value"), target:GetProperty("_MaxValue")
    --            grid.TxtStageStar1Num.text = CsXTextManagerGetText("DoomsdayMainTargetProgress", value, maxValue)
    --            grid.ImgProgressAim1.fillAmount = XUiHelper.GetFillAmountValue(value, maxValue)
    --        end
    --    )
    --
    --    self.PanelBranchlineTask.gameObject:SetActiveEx(false)
    --    self.PanelMainlineTask.gameObject:SetActiveEx(true)
    --else
    --    if not targetId then
    --        --点击了二级标题
    --        return
    --    end
    --
    --    --额外任务展示
    --    self.TxtDescSub.text = XDoomsdayConfigs.TargetConfig:GetProperty(targetId, "Desc")
    --
    --    local value, maxValue = target:GetProperty("_Value"), target:GetProperty("_MaxValue")
    --    self.TxtProgressNumSub.text = CsXTextManagerGetText("DoomsdayMainTargetProgress", value, maxValue)
    --    self.ImgProgressSub.fillAmount = XUiHelper.GetFillAmountValue(value, maxValue)
    --
    --    --额外任务通关提示
    --    self:RefreshTemplateGrids(
    --        self.SubTxtTips,
    --        XDoomsdayConfigs.TargetConfig:GetProperty(targetId, "Tips"),
    --        self.SubTipsContent,
    --        nil,
    --        "MainTargetTipGrids",
    --        function(grid, tips)
    --            local target = self.StageData:GetTarget(targetId)
    --            grid.SubTxtTips.text = tips
    --        end
    --    )
    --
    --    self.PanelMainlineTask.gameObject:SetActiveEx(false)
    --    self.PanelBranchlineTask.gameObject:SetActiveEx(true)
    --end
end

--==============================
---@desc 废弃的方法
--==============================
function XUiDoomsdayFubenTask:OnClickBtnGiveUp()
    --self:Close()
    --XDataCenter.DoomsdayManager.DoomsdayGiveUpTargetRequest(self.StageId, self.BtnTargetIdDic[self.SelectIndex])
end

--==============================
---@desc 废弃的方法
--==============================
function XUiDoomsdayFubenTask:GetCertainBtnModel(index, hasChild, pos, totalNum)
    --if index == BTN_INDEX.First then
    --    if hasChild then
    --        return self.BtnFirstHasSnd
    --    else
    --        return self.BtnFirst
    --    end
    --elseif index == BTN_INDEX.Second then
    --    if totalNum == 1 then
    --        return self.BtnSecondAll
    --    end
    --
    --    if pos == 1 then
    --        return self.BtnSecondTop
    --    elseif pos == totalNum then
    --        return self.BtnSecondBottom
    --    else
    --        return self.BtnSecond
    --    end
    --end
end
