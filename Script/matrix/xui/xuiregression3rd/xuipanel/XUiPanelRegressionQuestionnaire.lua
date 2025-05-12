
local XUiPanelRegressionBase = require("XUi/XUiRegression3rd/XUiPanel/XUiPanelRegressionBase")

---@class XUiPanelRegressionQuestionnaire
---@field ViewModel
local XUiPanelRegressionQuestionnaire = XClass(XUiPanelRegressionBase, "XUiPanelRegressionQuestionnaire")

local XUiGridRegressionSurvey = require('XUi/XUiRegression3rd/XUiGrid/XUiGridRegressionSurvey')

--region   ------------------重写父类方法 start-------------------
function XUiPanelRegressionQuestionnaire:InitCb()

end

function XUiPanelRegressionQuestionnaire:Show()
    self:Open()
    XMVCA.XDailyReset:SaveDailyRedPoint(XDataCenter.Regression3rdManager.SurveyDailyRedPointKey())
end

function XUiPanelRegressionQuestionnaire:Hide()
    self:Close()
end

function XUiPanelRegressionQuestionnaire:InitUi()
    self:InitDesc()
    self:InitSurveyGrids()
end
--endregion------------------重写父类方法 finish------------------

function XUiPanelRegressionQuestionnaire:InitDesc()
    self.TxtTitle.text = XRegression3rdConfigs.GetClientConfigValue('SurveyDesc', 1)
    self.TxtTips.text = XRegression3rdConfigs.GetClientConfigValue('SurveyDesc', 2)
end

function XUiPanelRegressionQuestionnaire:InitSurveyGrids()
    self._SurveyGrids = {}
    -- 根据配置表和Ui引用生成所有问卷显示
    local ids = XRegression3rdConfigs.GetSurveyCfgIds()
    for index, surveyId in ipairs(ids) do
        local go = self['BtnQuestionnaire'..index]
        if go then
            local cfg = XRegression3rdConfigs.GetSurveyCfgById(surveyId)
            if cfg then
                local grid = XUiGridRegressionSurvey.New(go, self, cfg)
                grid:Open()
                table.insert(self._SurveyGrids, grid)
            else
                go.gameObject:SetActiveEx(false)
            end
        end
    end
    
    -- 预估一部分长度控制多余部分隐藏
    local index = XTool.IsTableEmpty(ids) and 1 or #ids + 1
    for i = index, 10 do
        local go = self['BtnQuestionnaire'..i]
        if go then
            go.gameObject:SetActiveEx(false)
        else
            -- UI后缀索引一般都是递增的，中断则表示后面也没有了
            break
        end
    end
end

function XUiPanelRegressionQuestionnaire:RefreshView()
    
end


return XUiPanelRegressionQuestionnaire