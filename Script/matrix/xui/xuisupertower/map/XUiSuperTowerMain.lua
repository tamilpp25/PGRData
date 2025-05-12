local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
--===========================
--超级爬塔主页面
--===========================
local XUiSuperTowerMain = XLuaUiManager.Register(XLuaUi, "UiSuperTowerMain")
local XUiPanel3DMap = require("XUi/XUiSuperTower/Map/XUiPanel3DMap")
local XUiPanelStageSelect = require("XUi/XUiSuperTower/Map/XUiPanelStageSelect")
local XUiPanelThemeSelect = require("XUi/XUiSuperTower/Map/XUiPanelThemeSelect")
local XUiSTFunctionButton = require("XUi/XUiSuperTower/Common/XUiSTFunctionButton")
local CSTextManagerGetText = CS.XTextManager.GetText
local Tablepack = table.pack
local DefaultIndex = 1
function XUiSuperTowerMain:OnStart()
    self:InitSceneRoot()
    self:InitPanel()
    self:SetButtonCallBack()
    -- 自动关闭
    local endTime = XDataCenter.SuperTowerManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XLuaUiManager.Close("UiSuperTowerTedianUP")
            XDataCenter.SuperTowerManager.HandleActivityEndTime()
        else
            self:CheckTime()
        end
    end)
end

function XUiSuperTowerMain:OnDestroy()
    self.Panel3DMap:StopAllStageTimer()
    
    if self.FunctionBtnShop then
        self.FunctionBtnShop:OnDestroy()
    end
    
    if self.StageSelectPanel and self.StageSelectPanel.FunctionBtnSpecial then
        self.StageSelectPanel.FunctionBtnSpecial:OnDestroy()
    end

end

function XUiSuperTowerMain:OnEnable()
    XUiSuperTowerMain.Super.OnEnable(self)
    local IsShowSettleDark = XDataCenter.SuperTowerManager.CheckShowSettleDark()
    self:ShowSettleDark(IsShowSettleDark)
    self:UpdatePanel()
    self:CheckTime()
    -- self:CreatrTimer()
    self:CheckHitFaceStory()
    XRedPointManager.CheckOnceByButton(self.BtnRole, { 
        XRedPointConditions.Types.CONDITION_SUPERTOWER_ROLE_LEVELUP
        , XRedPointConditions.Types.CONDITION_SUPERTOWER_ROLE_PLUGIN })
    self:PlayAnimation("ButtonEnable")
    XDataCenter.GuideManager.CheckGuideOpen()
end

function XUiSuperTowerMain:OnDisable()
    XUiSuperTowerMain.Super.OnDisable(self)
    -- if self.Timer then
    --     XScheduleManager.UnSchedule(self.Timer)
    -- end
end

function XUiSuperTowerMain:OnGetEvents()
    return {
        XEventId.EVENT_ST_MAP_THEME_SELECT,
        XEventId.EVENT_ST_FINISH_FIGHT_COMPLETE
    }
end

function XUiSuperTowerMain:OnNotify(evt, ...)
    local args = Tablepack(...)
    if evt == XEventId.EVENT_ST_MAP_THEME_SELECT then
        self:SelectTheme(args[1], args[2])
    elseif evt == XEventId.EVENT_ST_FINISH_FIGHT_COMPLETE then
        self:ShowSettleDark(false)
    end
end

function XUiSuperTowerMain:ShowSettleDark(IsShow)
    self.SettleDark.gameObject:SetActiveEx(IsShow)
end

local CreateCameraKey = function(themeIndex, stageIndex)
    local str
    if stageIndex then
        str = themeIndex > 9 and "%d_%d" or "0%d_%d"
        return string.format(str, themeIndex, stageIndex)
    else
        str = themeIndex > 9 and "%d" or "0%d"
        return string.format(str, themeIndex)
    end
end

function XUiSuperTowerMain:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.PanelMapMain = root:FindTransform("PanelMapMain")

    self.CameraNear = {}
    self.Camera3DUi = {}

    self:InitCamera(root, self.CameraNear, "UiCamNearMain", "UiCamNearGrid")
    self:InitCamera(root, self.Camera3DUi, "UiCamMain", "UiCamGrid")
end

function XUiSuperTowerMain:InitCamera(root, cameraDic, cameraMainName, cameraName)
    local themeList = XDataCenter.SuperTowerManager.GetStageManager():GetAllThemeList()

    cameraDic[CreateCameraKey(0)] = root:FindTransform(cameraMainName)

    for themeIndex,theme in pairs(themeList or {}) do

        local key = CreateCameraKey(themeIndex)
        cameraDic[key] = root:FindTransform(string.format("%s%s", cameraName, key))

        for stageIndex,_ in pairs(theme:GetTargetStageList() or {}) do

            key = CreateCameraKey(themeIndex, stageIndex)
            cameraDic[key] = root:FindTransform(string.format("%s%s", cameraName, key))
        end
    end
end

function XUiSuperTowerMain:InitPanel()
    self.Panel3DMap = XUiPanel3DMap.New(self.PanelMapMain)
    self.StageSelectPanel = XUiPanelStageSelect.New(self.PanelStageSelect, self)
    self.ThemeSelectPanel = XUiPanelThemeSelect.New(self.PanelThemeSelect, self)

    local itemIds = XSuperTowerConfigs.GetMainAssetsPanelItemIds()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(itemIds, function()
            self.AssetActivityPanel:Refresh(itemIds)
        end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh(itemIds)

    self.IsInitSelect = true
end

function XUiSuperTowerMain:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnBag.CallBack = function()
        self:OnBtnBagClick()
    end
    
    self.FunctionBtnShop = XUiSTFunctionButton.New(self.BtnShop, function() self:OnBtnShopClick() end, XDataCenter.SuperTowerManager.FunctionName.Shop)
    self.FunctionBtnRole = XUiSTFunctionButton.New(self.BtnRole, function() self:OnBtnRoleClick() end, XDataCenter.SuperTowerManager.FunctionName.Transfinite)
    self:BindHelpBtn(self.BtnHelp, "SuperTowerMainHelp")
    
    self.PanelGuideButton:GetObject("Open01").CallBack = function()
        self:OnBtnGuideThemeClick()
    end
    
    self.PanelGuideButton:GetObject("Stage01").CallBack = function()
        self:OnBtnGuideStageClick()
    end
end

function XUiSuperTowerMain:OnBtnBackClick()
    if self:IsThemeSelect() then
        self:Close()
    else
        self:SelectTheme(XDataCenter.SuperTowerManager.ThemeIndex.ThemeAll)
    end
end

function XUiSuperTowerMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiSuperTowerMain:OnBtnBagClick()
    XLuaUiManager.Open("UiSuperTowerCall")
end

function XUiSuperTowerMain:OnBtnShopClick()
    XLuaUiManager.Open("UiSuperTowerShop")
end

function XUiSuperTowerMain:OnBtnRoleClick()
    XLuaUiManager.Open("UiSuperTowerRoleOverrun")
end

function XUiSuperTowerMain:OnBtnGuideThemeClick()
    local chapterData = self.Panel3DMap:GetChapterByIndex(DefaultIndex)
    local themeData = chapterData:GetTheme()
    themeData:OnBtnClick()
end

function XUiSuperTowerMain:OnBtnGuideStageClick()
    local chapterData = self.Panel3DMap:GetChapterByIndex(DefaultIndex)
    local stageData = chapterData:GetStageByIndex(DefaultIndex)
    stageData:OnBtnClick()
end

function XUiSuperTowerMain:CheckTime()
    local timeLeft = XDataCenter.SuperTowerManager.GetActivityEndTime() - XTime.GetServerNowTimestamp()
    self.StageSelectPanel:UpdateTime(timeLeft)
    self.ThemeSelectPanel:UpdateTime(timeLeft)
end

function XUiSuperTowerMain:CheckHitFaceStory()
    local activityId = XDataCenter.SuperTowerManager.GetActivityId()
    local hitFaceData = XSaveTool.GetData(string.format( "%sSuperTowerStory%s", XPlayer.Id, activityId))
    if not hitFaceData then
        XSaveTool.SaveData(string.format("%sSuperTowerStory%s", XPlayer.Id, activityId), true)
        local storyId = XDataCenter.SuperTowerManager.GetPrefaceStoryId()
        if storyId and not string.IsNilOrEmpty(storyId) then
            XDataCenter.MovieManager.PlayMovie(storyId)
        end
    end
end

function XUiSuperTowerMain:UpdatePanel()
    --XDataCenter.SuperTowerManager.GetStageManager():CheckReset()
    self.Panel3DMap:UpdatePanel()

    if self.IsInitSelect then
        if self.InitThemeIndex then
            self:SelectTheme(self.InitThemeIndex)
        else
            local index = XDataCenter.SuperTowerManager.GetCurSelectThemeIndex()
            self:SelectTheme(index or XDataCenter.SuperTowerManager.ThemeIndex.ThemeAll)
        end
    end

    if self:IsThemeSelect() then
        self.ThemeSelectPanel:UpdatePanel()
    else
        local stTheme = XDataCenter.SuperTowerManager.GetStageManager():GetAllThemeList()[self.CurThemeIndex]
        self.StageSelectPanel:UpdatePanel(stTheme)
    end

    self.ThemeSelectPanel:ShowPanel(self:IsThemeSelect())
    self.StageSelectPanel:ShowPanel(not self:IsThemeSelect())
    
    self.BtnBag:SetName(CSTextManagerGetText("STMainBtnBagName"))
    self.BtnShop:SetName(CSTextManagerGetText("STMainBtnShopName"))
    self.BtnRole:SetName(CSTextManagerGetText("STMainBtnRoleName"))
end

function XUiSuperTowerMain:SetCameraType(index, stageIndex)
    for k, _ in pairs(self.CameraNear) do
        self.CameraNear[k].gameObject:SetActiveEx(k == CreateCameraKey(index, stageIndex))
    end
    for k, _ in pairs(self.Camera3DUi) do
        self.Camera3DUi[k].gameObject:SetActiveEx(k == CreateCameraKey(index, stageIndex))
    end
end

function XUiSuperTowerMain:SelectTheme(themeIndex, stageIndex)
    if stageIndex then
        self:PlayAnimation("ButtonDisable")
        self.ButtonDisable = true
    else
        if self.ButtonDisable then
            self:PlayAnimation("ButtonEnable")
            self.ButtonDisable = false
        end
        self:PlayAnimation("QieHuan")
    end

    self:SetCameraType(themeIndex, stageIndex)

    if self.CurThemeIndex == themeIndex then
        return
    end

    self.CurThemeIndex = themeIndex
    self.Panel3DMap:SelectTheme(themeIndex)
    self:UpdatePanel()
    self.IsInitSelect = false
end

function XUiSuperTowerMain:IsThemeSelect()
    return self.CurThemeIndex == XDataCenter.SuperTowerManager.ThemeIndex.ThemeAll
end

function XUiSuperTowerMain:OnReleaseInst()
    return self.CurThemeIndex
end

function XUiSuperTowerMain:OnResume(data)
    self:ShowSettleDark(true)
    self.InitThemeIndex = data
end