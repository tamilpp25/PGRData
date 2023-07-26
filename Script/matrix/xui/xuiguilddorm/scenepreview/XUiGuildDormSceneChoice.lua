---@class UiGuildDormSceneChoice : XLuaUi
local XUiGuildDormSceneChoice = XLuaUiManager.Register(XLuaUi, "UiGuildDormSceneChoice")
local XUiGridGuildDormScene = require("XUi/XUiGuildDorm/ScenePreview/XUiGridGuildDormScene")
local XUiGridGuildDormSceneLabel = require("XUi/XUiGuildDorm/ScenePreview/XUiGridGuildDormSceneLabel")
function XUiGuildDormSceneChoice:OnStart()
    self.LabelCol = {}
    self:InitLeftPanel()
    self:RegisterButton()
end

function XUiGuildDormSceneChoice:RegisterButton()
    self.BtnTanchuangClose.CallBack = function() 
        self:Close()
    end
    
    self.BtnTongBlue.CallBack = function()
        if self:CheckSpecialThemeId() then
            return
        end
        XDataCenter.GuildDormManager.RequestSetRoomTheme(self.CurrId,function() 
            
        end)
    end

    self.BtnLabel.CallBack = function()
        XLuaUiManager.Open("UiGuildRoomSceneTips", self.CurrId)
    end
    self.BtnGoto.CallBack = function() 
        local config = XGuildDormConfig.GetThemeCfgById(self.CurrId)
        XFunctionManager.SkipInterface(config.ShopSkipId)
    end
    
    self.BtnPreview.CallBack = function() 
        XLuaUiManager.Open("UiGuildRoomTemplate", self.CurrId)
    end
end

function XUiGuildDormSceneChoice:CheckSpecialThemeId()
    -- 当前装扮的主题
    local currThemeId = XDataCenter.GuildDormManager.GetThemeId()
    local currConfig = XGuildDormConfig.GetThemeCfgById(currThemeId)
    -- 试用
    local currIsTime = XFunctionManager.CheckInTimeByTimeId(currConfig.TimeId)
    if currIsTime then
        XUiManager.TipText("GuildDormSpecialThemeIdTips")
        return true
    end
    return false
end

function XUiGuildDormSceneChoice:OnEnable()
    self:RefreshRightPanel()
end

function XUiGuildDormSceneChoice:OnDisable()
    self:StopTimer()
end

function XUiGuildDormSceneChoice:InitLeftPanel()
    self.LeftGridList = {}
    local templateList = XGuildDormConfig.GetShowThemeConfigs(XGuildDormConfig.TableKey.Theme)
    for _, template in  pairs(templateList) do
        local grid = self.LeftGridList[template.Id]
        if not grid then
            local obj = CS.UnityEngine.GameObject.Instantiate(self.GridScene,self.PanelScene)
            grid = XUiGridGuildDormScene.New(obj, function(id)
                self:OnClickTemplate(id)
            end)
            self.LeftGridList[template.Id] = grid
        end
        grid:Refresh(template.Id)
    end
    if templateList and #templateList > 0 then
        self.CurrId = XDataCenter.GuildDormManager.GetThemeId()
        self:OnClickTemplate(self.CurrId)
    end
    self.GridScene.gameObject:SetActiveEx(false)
end

function XUiGuildDormSceneChoice:RefreshRightPanel()
    self:RefreshUi()
    self:RefreshLabels()
end

function XUiGuildDormSceneChoice:RefreshUi()
    local config = XGuildDormConfig.GetThemeCfgById(self.CurrId)
    -- 试用
    local isTime = XFunctionManager.CheckInTimeByTimeId(config.TimeId)
    local isBuy = XDataCenter.GuildManager.HasTheme(self.CurrId)
    local needBuy = config.NeedBuy ~= 0
    
    local currThemeId = XDataCenter.GuildDormManager.GetThemeId()
    local currConfig = XGuildDormConfig.GetThemeCfgById(currThemeId)
    -- 试用
    local currIsTime = XFunctionManager.CheckInTimeByTimeId(currConfig.TimeId)
    
    self.BtnTongBlue.gameObject:SetActiveEx(isBuy or (not needBuy) or isTime)
    self.BtnGoto.gameObject:SetActiveEx(not isBuy and needBuy and not isTime)
    
    local isTongBlueDisable = currThemeId == self.CurrId and true or currIsTime
    self.BtnTongBlue:SetDisable(isTongBlueDisable, currThemeId ~= self.CurrId)
    
    self.RImgTip:SetRawImage(config.Image)
    self.TxtTipName.text = config.Name
    self.BtnPreview.gameObject:SetActiveEx(#config.PreviewImageList > 0)
    self.PanelTrialTime.gameObject:SetActiveEx(isTime)
    if isTime then
        self.EndTimer = XFunctionManager.GetEndTimeByTimeId(config.TimeId)
        if not self.Timer then
            self:StartTimer()
        else
            self:UpdateTimer()
        end
    end
end

function XUiGuildDormSceneChoice:RefreshLabels()
    local config = XGuildDormConfig.GetThemeCfgById(self.CurrId)
    local labelList = config.Labels
    self.BtnLabel.gameObject:SetActiveEx(labelList and #labelList > 0)
    for _, labelCol in pairs(self.LabelCol) do
        labelCol:SetActive(false)
    end
    for i, labelStr in ipairs(labelList) do
        local label = self.LabelCol[i]
        if not label then
            local obj = CS.UnityEngine.GameObject.Instantiate(self.PanelCol, self.PanelLabel)
            label = XUiGridGuildDormSceneLabel.New(obj, function()
                XLuaUiManager.Open("UiGuildRoomSceneTips", self.CurrId)
            end)
            self.LabelCol[i] = label
        end
        label:SetText(labelStr)
        label:SetActive(true)
    end
    self.PanelCol.gameObject:SetActiveEx(false)
end

function XUiGuildDormSceneChoice:OnClickTemplate(id)
    self.CurrId = id
    self.LeftGridList[id]:SetSelect(true)
    for _, grid in pairs(self.LeftGridList) do
        if grid.Id ~= id then
            grid:SetSelect(false)
        end
    end
    self:RefreshRightPanel()
end

function XUiGuildDormSceneChoice:StartTimer()
    if self.Timer then
        self:StopTimer()
    end

    self:UpdateTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTimer()
    end, XScheduleManager.SECOND)
end

function XUiGuildDormSceneChoice:UpdateTimer()
    if XTool.UObjIsNil(self.TxtDesc) then
        self:StopTimer()
        return
    end

    local endTime = self.EndTimer
    local leftTime = endTime - XTime.GetServerNowTimestamp()
    if leftTime <= 0 then
        self:StopTimer()
        return
    end
    local timeText = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.DEFAULT)
    self.TxtDesc.text = XUiHelper.GetText("GuildDormSceneTrialTime", timeText)
end

function XUiGuildDormSceneChoice:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiGuildDormSceneChoice