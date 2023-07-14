--================
--超限乱斗选择关卡页面
--================
local XUiSuperSmashBrosSelectStage = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosSelectStage")

function XUiSuperSmashBrosSelectStage:OnStart(mode)
    self.Mode = mode
    self:InitPanels()
    self:SetActivityTimeLimit() --设置活动关闭时处理

    self.PanelNoticeTitleBtnGroup:SelectIndex(self.CurrentTab or 1) --第一次进入默认选择地图
end
--================
--初始化所有子面板
--================
function XUiSuperSmashBrosSelectStage:InitPanels()
    self:InitBtns()
    -- self:InitPanelMap()
    -- self:InitPanelEnviorn()
end
--================
--初始化页面按钮
--================
function XUiSuperSmashBrosSelectStage:InitBtns()
    self.BtnMainUi.CallBack = handler(self, self.OnClickBtnMainUi)
    self.BtnBack.CallBack = handler(self, self.OnClickBtnBack)
    self:BindHelpBtn(self.BtnHelp, "SuperSmashBrosHelp")
    self.BtnConfirm.CallBack = function() self:OnClickConfirm() end
    self.PanelNoticeTitleBtnGroup:Init({self.BtnMap, self.BtnEnvironment}, function(index) self:OnSelectTab(index) end)

    self.BtnTabGrid = {}
    -- 初始化选择按钮
    local tabGroup = {}
    local sceneGroupId = self.Mode:GetMapLibraryId()
    self.Scenes = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.Group2SceneDic, sceneGroupId)
    for i, scene in pairs(self.Scenes) do
        local btn = self.BtnTabGrid[i]
        if not btn then
            local go = #self.BtnTabGrid == 0 and self.BtnMapGrid or XUiHelper.Instantiate(self.BtnMapGrid, self.PanelNoticeTitleBtnGroup.transform)
            btn = go:GetComponent("XUiButton")
            self.BtnTabGrid[i] = btn
        end
        btn:SetName(scene.EnvName)
    end

    self.PanelNoticeTitleBtnGroup:Init(self.BtnTabGrid, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end
--================
--选择按钮组事件
--================
function XUiSuperSmashBrosSelectStage:OnClickTabCallBack(tabIndex)
    if self.CurrentTab and self.CurrentTab == tabIndex then
        return
    end
    self:PlayAnimation("QieHuan")
    self.CurrentTab = tabIndex
    local currentScene = self.Scenes[tabIndex]
    self.BtnTabGrid[tabIndex]:SetRawImage(currentScene.BtnIcon)
    self:SetSelectScene(currentScene)
    self.ImgMap:SetRawImage(currentScene.ThumbnailPath)
    self.TxtBUFF.text = currentScene.Description
end
--================
--点击关闭时
--================
function XUiSuperSmashBrosSelectStage:OnClickClose()
    self:Close()
end
--================
--点击确认时
--================
function XUiSuperSmashBrosSelectStage:OnClickConfirm()
    XLuaUiManager.Open("UiSuperSmashBrosPick", self.Mode, self.SelectEnvironment, self.SelectScene)
end
--==============
--主界面按钮
--==============
function XUiSuperSmashBrosSelectStage:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end
--==============
--返回按钮
--==============
function XUiSuperSmashBrosSelectStage:OnClickBtnBack()
    self:Close()
end
--================
--设置选择场景
--================
function XUiSuperSmashBrosSelectStage:SetSelectScene(sceneCfg)
    self.SelectScene = sceneCfg
end
--==============
--设置活动关闭时处理
--==============
function XUiSuperSmashBrosSelectStage:SetActivityTimeLimit()
    -- 自动关闭
    local endTime = XDataCenter.SuperSmashBrosManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                XDataCenter.SuperSmashBrosManager.OnActivityEndHandler()
            end
        end)
end